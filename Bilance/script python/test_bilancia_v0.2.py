#!/usr/bin/env python3
"""
Dual Serial Communication Manager
Gestisce la comunicazione seriale su due porte:
- /dev/ttyUSB0: per lettura dati e comandi di lettura
- /dev/ttyAMA10: per modificare le impostazioni di setup
"""

import serial
import threading
import time
import logging
from typing import Optional, Callable, Dict, List
from enum import Enum

# Configurazione logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='ArchiScale.log',
    filemode='a'
)
logger = logging.getLogger('ArchiScale')


class PortType(Enum):
    """Enumera i tipi di porte seriali utilizzate"""
    DATA_PORT = "data"  # /dev/ttyUSB0 - lettura dati in uscita sulla porta seriale USB
    SETUP_PORT = "setup"  # /dev/ttyAMA10 - invio dati per la configurazione della bilancia


class SerialCommands(Enum):
    """
    Enumerazione dei comandi seriali disponibili per scale 3590ET/3590EGT
    Ogni comando ha un numero identificativo e la stringa corrispondente
    """
    # Weight reading commands (1-5)
    RALL = (1, "RALL")  # Reading of the scale data
    READ = (2, "READ")  # Reading of the scale weight
    REXT = (3, "REXT")  # Reading of the scale weights
    GR10 = (4, "GR10")  # Get the net weight in high resolution
    R = (5, "R")  # Reading of the scale weight

    # Weight setting commands (6-15)
    SPMU = (6, "SPMU")  # Sets the average piece weight in the set AVG unit
    STPD = (7, "STPD")  # This command is the same as STPT
    STPT = (8, "STPT")  # Setpoint setting
    T = (9, "T")  # Semi automatic tare function
    TARE = (10, "TARE")  # Semi automatic tare function
    TMAN = (11, "TMAN")  # Preset tare function
    W = (12, "W")  # Preset tare function
    X = (13, "X")  # Sets the average piece weight in the set AVG unit
    ZERO = (14, "ZERO")  # Zero scale function
    Z = (15, "Z")  # Zero scale function

    # Scale commands (16-29)
    CGCH = (16, "CGCH")  # Change the weighing channel
    CMDOFF = (17, "CMDOFF")  # Turns the indicator off
    CMDRESET = (18, "CMDRESET")  # Restarts the indicator
    CMDSAVE = (19, "CMDSAVE")  # Save the setup parameter
    CMDSETUP = (20, "CMDSETUP")  # Enter in the setup environment
    FREZ = (21, "FREZ")  # Stores the present data weights in the scale frozen data area
    MVOL = (22, "MVOL")  # Get the micro Volts of the selected instrument channel
    NTGS = (23, "NTGS")  # Switches the main weight display value from gross to net and vice versa
    Q = (24, "Q")  # Change the weighing channel
    RAZF = (25, "RAZF")  # Get the ADC value of the selected instrument channel
    SN = (26, "SN")  # Reading of the instrument serial number
    STAT = (27, "STAT")  # Reading of the instrument working state
    VER = (28, "VER")  # Reading of the instrument model and firmware version

    # Power commands (30)
    ALIM = (30, "ALIM")  # Reading of power supply and battery levels

    # Alibi memory commands (31-33)
    ALRD = (31, "ALRD")  # Alibi memory reading
    ALDL = (32, "ALDL")  # Clearing of the alibi memory
    PID = (33, "PID")  # Stores weigh data in the alibi memory and get alibi ID value

    # Analog output command (34)
    ANOU = (34, "ANOU")  # Analog output value setting

    # Display commands (35-41)
    DINT = (35, "DINT")  # Sets the interval of the message displayed with the DISP command
    DISP = (36, "DISP")  # Displays of a message on the system message area
    GINR = (37, "GINR")  # Get the numeric value inserted by the user
    IALA = (38, "IALA")  # Set the instrument scale in the alphanumerical input state
    INUN = (39, "INUN")  # Set the instrument scale in the numeric input state
    RUBU = (40, "RUBU")  # Reading of the last data inserted by the user after the execution of the IALA command
    WUBU = (41, "WUBU")  # Writes data in the user buffer

    # Keys related commands (42-50)
    ATS = (42, "ATS")  # Enable / Disable the automatic transmission of the pressed keys
    CLEAR = (43, "CLEAR")  # Simulates the pressure of the CLEAR key
    C = (44, "C")  # Simulates the pressure of the CLEAR key
    EKBB = (45, "EKBB")  # Clear the keyboard buffer
    EXIT = (46, "EXIT")  # Simulates the pressure of the OK key
    GKBB = (47, "GKBB")  # Reading of the pressed buffered keys
    KEYE = (48, "KEYE")  # Keyboard enable
    KEYP = (49, "KEYP")  # Simulation of a key / button pressure
    KEYR = (50, "KEYR")  # Simulation of the release of the key

    # Audio buzzer commands (51-53)
    BEEP = (51, "BEEP")  # Activates the scale buzzer acoustic device
    BPO = (52, "BPO")  # Activates the scale buzzer acoustic device for no more than 10 seconds
    BPF = (53, "BPF")  # Turns the scale buzzer acoustic device off

    # Serial ports commands (54-57)
    BAUD = (54, "BAUD")  # Set the baud rate of the pc serial port
    BRIDGE = (55, "BRIDGE")  # Activates a bridge between printer or AUX serial port and PC serial port
    ECO = (56, "ECO")  # Echo of the received characters
    ECHO = (57, "ECHO")  # Echo of the received characters

    # Print commands (58-61)
    PRNT = (58, "PRNT")  # Simple print function execution
    PRV = (59, "PRV")  # Sets the print format related to a print function
    P = (60, "P")  # Simple print function execution
    TOPR = (61, "TOPR")  # Sends data to the printer port

    # Digital inputs commands (62-63)
    GETI = (62, "GETI")  # Reading of the digital inputs status
    INPU = (63, "INPU")  # Reading of the digital inputs status

    # Digital outputs commands (64)
    OUTP = (64, "OUTP")  # Set the digital outputs states

    # Database related commands (65-69)
    GREC = (65, "GREC")  # Reading of the selected record of a database
    NREC = (66, "NREC")  # Reading of the number of occupied records and the total number of records of a database
    RREC = (67, "RREC")  # Reading of a record of a database
    SREC = (68, "SREC")  # Selects a record of a database
    WREC = (69, "WREC")  # Writing of a record of a database

    # Additional commands
    LNKF = (70, "LNKF")  # Sets the print format related to a print function
    PAPER = (71, "PAPER")  # Reading of paper status of the connected printer with paper sensor

    def __init__(self, number: int, command: str):
        self.number = number
        self.command = command

    @classmethod
    def get_command_list(cls) -> List[tuple]:
        """Restituisce la lista di tutti i comandi con numero e descrizione"""
        return [(cmd.number, cmd.command, cmd._name_) for cmd in cls]

    @classmethod
    def get_command_by_number(cls, number: int) -> Optional['SerialCommands']:
        """Trova un comando dal suo numero identificativo"""
        for cmd in cls:
            if cmd.number == number:
                return cmd
        return None

    @classmethod
    def get_command_by_name(cls, name: str) -> Optional['SerialCommands']:
        """Trova un comando dal suo nome"""
        try:
            return cls[name.upper()]
        except KeyError:
            return None


class DualSerialManager:
    """
    Classe per gestire la comunicazione seriale su due porte separate:
    - Porta dati: per lettura continua e comandi di lettura
    - Porta setup: per modificare configurazioni del dispositivo
    """

    def __init__(self,
                 data_port: str = '/dev/ttyUSB0',
                 setup_port: str = '/dev/ttyAMA10',
                 baudrate: int = 9600,
                 timeout: float = 1.0):
        """
        Inizializza il gestore delle comunicazioni seriali

        Args:
            data_port (str): Porta per lettura dati (/dev/ttyUSB0)
            setup_port (str): Porta per setup (/dev/ttyAMA10)
            baudrate (int): Velocità di comunicazione in baud
            timeout (float): Timeout per le operazioni di lettura/scrittura
        """
        # Configurazione porte
        self.ports_config = {
            PortType.DATA_PORT: {
                'port': data_port,
                'baudrate': baudrate,
                'timeout': timeout,
                'connection': None
            },
            PortType.SETUP_PORT: {
                'port': setup_port,
                'baudrate': baudrate,
                'timeout': timeout,
                'connection': None
            }
        }

        # Thread per lettura continua
        self.reading_thread: Optional[threading.Thread] = None
        self.is_reading = False
        self.read_callback: Optional[Callable] = None

        # Lock per thread safety
        self.data_lock = threading.Lock()
        self.setup_lock = threading.Lock()

        logger.info("DualSerialManager inizializzato")

    def connect(self, port_type: PortType) -> bool:
        """
        Stabilisce connessione con la porta specificata

        Args:
            port_type (PortType): Tipo di porta da connettere

        Returns:
            bool: True se connessione riuscita, False altrimenti
        """
        try:
            config = self.ports_config[port_type]

            # Chiudi connessione esistente se presente
            if config['connection'] and config['connection'].is_open:
                config['connection'].close()

            # Crea nuova connessione con i parametri base
            config['connection'] = serial.Serial(
                port=config['port'],
                baudrate=config['baudrate'],
                timeout=config['timeout'],
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE
            )

            logger.info(f"Connesso a {config['port']} ({port_type.value})")
            return True

        except serial.SerialException as e:
            logger.error(f"Errore connessione {port_type.value}: {e}")
            return False
        except Exception as e:
            logger.error(f"Errore generico connessione {port_type.value}: {e}")
            return False

    def connect_all(self) -> Dict[PortType, bool]:
        """
        Connette entrambe le porte seriali

        Returns:
            Dict[PortType, bool]: Stato connessione per ogni porta
        """
        results = {}
        for port_type in PortType:
            results[port_type] = self.connect(port_type)
        return results

    def disconnect(self, port_type: PortType) -> bool:
        """
        Disconnette la porta specificata

        Args:
            port_type (PortType): Tipo di porta da disconnettere

        Returns:
            bool: True se disconnessione riuscita
        """
        try:
            config = self.ports_config[port_type]
            if config['connection'] and config['connection'].is_open:
                config['connection'].close()
                logger.info(f"Disconnesso da {config['port']} ({port_type.value})")
            config['connection'] = None
            return True
        except Exception as e:
            logger.error(f"Errore disconnessione {port_type.value}: {e}")
            return False

    def disconnect_all(self):
        """Disconnette tutte le porte seriali"""
        # Ferma lettura continua
        self.stop_continuous_reading()

        # Disconnetti tutte le porte
        for port_type in PortType:
            self.disconnect(port_type)

    def is_connected(self, port_type: PortType) -> bool:
        """
        Verifica se la porta è connessa

        Args:
            port_type (PortType): Tipo di porta da verificare

        Returns:
            bool: True se connessa e aperta
        """
        config = self.ports_config[port_type]
        return config['connection'] is not None and config['connection'].is_open

    def send_read_command(self, command: str) -> Optional[str]:
        """
        Invia un comando di lettura sulla porta dati (/dev/ttyUSB0)

        Args:
            command (str): Comando da inviare

        Returns:
            Optional[str]: Risposta ricevuta o None se errore
        """
        if not self.is_connected(PortType.DATA_PORT):
            logger.error("Porta dati non connessa")
            return None

        try:
            with self.data_lock:
                connection = self.ports_config[PortType.DATA_PORT]['connection']

                # Pulisci buffer di input
                connection.flushInput()

                # Invia comando (aggiunge \r\n se non presente)
                if not command.endswith(('\r\n', '\n')):
                    command += '\r\n'

                connection.write(command.encode('utf-8'))
                logger.info(f"Comando lettura inviato: {command.strip()}")

                # Attendi risposta
                time.sleep(0.1)

                # Leggi risposta
                response = ""
                start_time = time.time()
                while time.time() - start_time < self.ports_config[PortType.DATA_PORT]['timeout']:
                    if connection.in_waiting > 0:
                        data = connection.read(connection.in_waiting).decode('utf-8', errors='ignore')
                        response += data

                        # Se troviamo un terminatore, interrompi
                        if '\n' in response or '\r' in response:
                            break
                    time.sleep(0.01)

                response = response.strip()
                if response:
                    logger.info(f"Risposta comando lettura: {response}")
                    return response
                else:
                    logger.warning("Nessuna risposta al comando di lettura")
                    return None

        except Exception as e:
            logger.error(f"Errore invio comando lettura: {e}")
            return None

    def send_serial_command(self, command_input, parameters: str = "") -> Optional[str]:
        """
        Invia un comando seriale sulla porta setup (/dev/ttyAMA10)

        Args:
            command_input: Può essere:
                - int: numero del comando (da SerialCommands enum)
                - str: nome del comando (es. "READ", "ZERO")
                - SerialCommands: enum diretto
            parameters (str): Parametri aggiuntivi per il comando (opzionali)

        Returns:
            Optional[str]: Risposta ricevuta o None se errore
        """
        if not self.is_connected(PortType.SETUP_PORT):
            logger.error("Porta setup non connessa")
            return None

        # Determina il comando da inviare
        command_enum = None

        if isinstance(command_input, int):
            command_enum = SerialCommands.get_command_by_number(command_input)
        elif isinstance(command_input, str):
            command_enum = SerialCommands.get_command_by_name(command_input)
        elif isinstance(command_input, SerialCommands):
            command_enum = command_input

        if command_enum is None:
            logger.error(f"Comando non riconosciuto: {command_input}")
            return None

        try:
            with self.setup_lock:
                connection = self.ports_config[PortType.SETUP_PORT]['connection']

                # Pulisci buffer di input
                connection.flushInput()

                # Costruisci il comando completo
                full_command = command_enum.command
                if parameters:
                    full_command += " " + parameters

                # Converti il comando in lista di caratteri ASCII
                command_chars = list(full_command)

                # Aggiungi terminatori CR e LF come caratteri separati
                command_chars.extend(['\r', '\n'])

                logger.info(f"Comando da inviare: {command_enum.command} (#{command_enum.number})")
                logger.debug(f"Caratteri ASCII: {[ord(c) for c in command_chars]}")

                # Invia ogni carattere separatamente
                for char in command_chars:
                    connection.write(char.encode('ascii'))
                    time.sleep(0.001)  # Piccola pausa tra i caratteri per stabilità

                logger.info(f"Comando seriale inviato: {full_command}")

                # Attendi risposta
                time.sleep(0.2)

                # Leggi risposta
                response = ""
                start_time = time.time()
                timeout = self.ports_config[PortType.SETUP_PORT]['timeout'] * 2

                while time.time() - start_time < timeout:
                    if connection.in_waiting > 0:
                        data = connection.read(connection.in_waiting).decode('ascii', errors='ignore')
                        response += data

                        # Se troviamo un terminatore completo, interrompi
                        if '\r\n' in response or response.endswith('\n'):
                            break
                    time.sleep(0.01)

                response = response.strip()
                if response:
                    logger.info(f"Risposta comando seriale: {response}")
                    return response
                else:
                    logger.warning("Nessuna risposta al comando seriale")
                    return None

        except Exception as e:
            logger.error(f"Errore invio comando seriale: {e}")
            return None

    def get_available_commands(self) -> List[tuple]:
        """
        Restituisce la lista di tutti i comandi disponibili

        Returns:
            List[tuple]: Lista di tuple (numero, comando, descrizione)
        """
        return SerialCommands.get_command_list()

    def send_command_by_number(self, command_number: int, parameters: str = "") -> Optional[str]:
        """
        Metodo di convenienza per inviare un comando usando il numero

        Args:
            command_number (int): Numero del comando (1-71)
            parameters (str): Parametri aggiuntivi

        Returns:
            Optional[str]: Risposta del comando
        """
        return self.send_serial_command(command_number, parameters)

    def send_command_by_name(self, command_name: str, parameters: str = "") -> Optional[str]:
        """
        Metodo di convenienza per inviare un comando usando il nome

        Args:
            command_name (str): Nome del comando (es. "READ", "ZERO")
            parameters (str): Parametri aggiuntivi

        Returns:
            Optional[str]: Risposta del comando
        """
        return self.send_serial_command(command_name, parameters)

    def start_continuous_reading(self, callback: Callable[[str], None] = None):
        """
        Inizia la lettura continua dei dati dalla porta dati

        Args:
            callback (Callable): Funzione da chiamare per ogni dato ricevuto
        """
        if self.is_reading:
            logger.warning("Lettura continua già attiva")
            return

        if not self.is_connected(PortType.DATA_PORT):
            logger.error("Porta dati non connessa, impossibile avviare lettura continua")
            return

        self.read_callback = callback
        self.is_reading = True
        self.reading_thread = threading.Thread(target=self._continuous_read_loop, daemon=True)
        self.reading_thread.start()
        logger.info("Lettura continua avviata")

    def stop_continuous_reading(self):
        """Ferma la lettura continua dei dati"""
        if self.is_reading:
            self.is_reading = False
            if self.reading_thread and self.reading_thread.is_alive():
                self.reading_thread.join(timeout=2.0)
            logger.info("Lettura continua fermata")

    def _continuous_read_loop(self):
        """Loop interno per la lettura continua (eseguito in thread separato)"""
        connection = self.ports_config[PortType.DATA_PORT]['connection']
        buffer = ""

        while self.is_reading:
            try:
                if connection.in_waiting > 0:
                    # Leggi dati disponibili
                    data = connection.read(connection.in_waiting).decode('utf-8', errors='ignore')
                    buffer += data

                    # Processa linee complete
                    while '\n' in buffer or '\r' in buffer:
                        if '\r\n' in buffer:
                            line, buffer = buffer.split('\r\n', 1)
                        elif '\n' in buffer:
                            line, buffer = buffer.split('\n', 1)
                        elif '\r' in buffer:
                            line, buffer = buffer.split('\r', 1)

                        line = line.strip()
                        if line:  # Ignora linee vuote
                            logger.info(f"Dati ricevuti: {line}")

                            # Chiama callback se definito
                            if self.read_callback:
                                try:
                                    self.read_callback(line)
                                except Exception as e:
                                    logger.error(f"Errore nel callback: {e}")

                time.sleep(0.01)  # Piccola pausa per non sovraccaricare CPU

            except Exception as e:
                logger.error(f"Errore nella lettura continua: {e}")
                time.sleep(0.1)

        logger.info("Loop di lettura continua terminato")

    def get_status(self) -> Dict:
        """
        Restituisce lo stato delle connessioni seriali

        Returns:
            Dict: Stato delle connessioni
        """
        status = {
            'data_port': {
                'port': self.ports_config[PortType.DATA_PORT]['port'],
                'connected': self.is_connected(PortType.DATA_PORT),
                'baudrate': self.ports_config[PortType.DATA_PORT]['baudrate']
            },
            'setup_port': {
                'port': self.ports_config[PortType.SETUP_PORT]['port'],
                'connected': self.is_connected(PortType.SETUP_PORT),
                'baudrate': self.ports_config[PortType.SETUP_PORT]['baudrate']
            },
            'continuous_reading': self.is_reading
        }
        return status


def data_received_callback(data: str):
    """
    Callback di esempio per elaborare i dati ricevuti

    Args:
        data (str): Dati ricevuti dalla porta seriale
    """
    print(f" Nuovo dato ricevuto: {data}")

    # Qui puoi aggiungere la logica per elaborare i dati
    # Ad esempio: salvataggio su file, parsing, analisi, ecc.

def main():
    """Funzione principale di esempio"""
    # Crea il gestore delle comunicazioni seriali
    serial_manager = DualSerialManager()

    try:
        print(" Connessione alle porte seriali...")
        connections = serial_manager.connect_all()

        # Verifica connessioni
        for port_type, connected in connections.items():
            status = " CONNESSA" if connected else " ERRORE"
            print(f"   {port_type.value}: {status}")

        # Mostra stato
        print("\n Stato delle connessioni:")
        status = serial_manager.get_status()
        for port_name, port_info in status.items():
            if port_name != 'continuous_reading':
                print(f"   {port_info['port']}: {'Connessa' if port_info['connected'] else 'Disconnessa'}")

        # Avvia lettura continua se la porta dati è connessa
        if serial_manager.is_connected(PortType.DATA_PORT):
            print("\n Avvio lettura continua...")
            serial_manager.start_continuous_reading(data_received_callback)

        # Menu interattivo
        print("\n" + "=" * 60)
        print("MENU COMANDI")
        print("=" * 60)
        print("1. Invia comando di lettura")
        print("2. Invia comando seriale per numero")
        print("3. Mostra comandi disponibili")
        print("4. Mostra stato")
        print("5. Ferma/Avvia lettura continua")
        print("0. Esci")
        print("=" * 60)

        while True:
            try:
                choice = input("\n Inserisci scelta: ").strip()

                if choice == '1':
                    command = input("Comando di lettura: ").strip()
                    if command:
                        response = serial_manager.send_read_command(command)
                        if response:
                            print(f" Risposta: {response}")
                        else:
                            print(" Nessuna risposta ricevuta")

                elif choice == '2':
                    try:
                        cmd_num = int(input("Numero comando (1-71): ").strip())
                        params = input("Parametri (opzionali): ").strip()
                        response = serial_manager.send_command_by_number(cmd_num, params)
                        if response:
                            print(f" Risposta: {response}")
                        else:
                            print(" Nessuna risposta ricevuta")
                    except ValueError:
                        print(" Numero comando non valido")

                elif choice == '3':
                    print("\n Comandi disponibili:")
                    commands = serial_manager.get_available_commands()

                    # Raggruppa comandi per categoria
                    categories = {
                        "Lettura peso (1-5)": [(n, c, d) for n, c, d in commands if 1 <= n <= 5],
                        "Impostazione peso (6-15)": [(n, c, d) for n, c, d in commands if 6 <= n <= 15],
                        "Comandi bilancia (16-29)": [(n, c, d) for n, c, d in commands if 16 <= n <= 29],
                        "Alimentazione (30)": [(n, c, d) for n, c, d in commands if n == 30],
                        "Memoria alibi (31-33)": [(n, c, d) for n, c, d in commands if 31 <= n <= 33],
                        "Output analogico (34)": [(n, c, d) for n, c, d in commands if n == 34],
                        "Display (35-41)": [(n, c, d) for n, c, d in commands if 35 <= n <= 41],
                        "Tastiera (42-50)": [(n, c, d) for n, c, d in commands if 42 <= n <= 50],
                        "Buzzer audio (51-53)": [(n, c, d) for n, c, d in commands if 51 <= n <= 53],
                        "Porte seriali (54-57)": [(n, c, d) for n, c, d in commands if 54 <= n <= 57],
                        "Stampa (58-61)": [(n, c, d) for n, c, d in commands if 58 <= n <= 61],
                        "Input/Output digitali (62-64)": [(n, c, d) for n, c, d in commands if 62 <= n <= 64],
                        "Database (65-69)": [(n, c, d) for n, c, d in commands if 65 <= n <= 69],
                        "Altri (70-71)": [(n, c, d) for n, c, d in commands if 70 <= n <= 71]
                    }

                    show_all = input("Mostrare tutti i comandi? (s/n): ").strip().lower() == 's'

                    if show_all:
                        for category, cmd_list in categories.items():
                            if cmd_list:
                                print(f"\n  {category}:")
                                for num, cmd, desc in cmd_list:
                                    print(f"    {num:2d}: {cmd:<10}")
                    else:
                        print("   Categorie principali:")
                        print("    1-5:   Comandi lettura peso (READ, RALL, etc.)")
                        print("    6-15:  Comandi impostazione peso (ZERO, TARE, etc.)")
                        print("    16-29: Comandi bilancia (STAT, VER, etc.)")
                        print("    30+:   Altri comandi specializzati")
                        print("\n   Usa opzione 5 e rispondi 's' per lista completa")

                elif choice == '4':
                    print("\n Stato attuale:")
                    status = serial_manager.get_status()
                    for port_name, port_info in status.items():
                        if port_name == 'continuous_reading':
                            print(f"   Lettura continua: {'Attiva' if port_info else 'Inattiva'}")
                        else:
                            conn_status = 'Connessa' if port_info['connected'] else 'Disconnessa'
                            print(f"   {port_info['port']}: {conn_status} @ {port_info['baudrate']} baud")

                elif choice == '5':
                    if serial_manager.is_reading:
                        serial_manager.stop_continuous_reading()
                        print(" Lettura continua fermata")
                    else:
                        if serial_manager.is_connected(PortType.DATA_PORT):
                            serial_manager.start_continuous_reading(data_received_callback)
                            print("  Lettura continua avviata")
                        else:
                            print(" Porta dati non connessa")

                elif choice == '0':
                    break

                else:
                    print(" Scelta non valida")

            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f" Errore: {e}")

    finally:
        print("\n Disconnessione e pulizia...")
        serial_manager.disconnect_all()
        print(" Programma terminato")

if __name__ == "__main__":
    main()