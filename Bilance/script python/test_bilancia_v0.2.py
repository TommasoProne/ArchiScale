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
from typing import Optional, Callable, Dict
from enum import Enum

# Configurazione logging

# !!!chiedere a Lorenzo che tipo di file preferisce per il documento di log!!!

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='ArchiScale.txt',  #nome del file di gioco
    filemode='a' # 'a' per append. 'w' per sovrascrivere
)
logger = logging.getLogger('ArchiScale')


class PortType(Enum):
    """Enumera i tipi di porte seriali utilizzate"""
    DATA_PORT = "data"  # /dev/ttyUSB0 - lettura dati in uscita sulla porta seriale USB (adattatore USB-seriale 9pin)
    SETUP_PORT = "setup"  # /dev/ttyAMA10 - invio dati per la configurazione della bilancia, collegamento con pin alla porta seriale della scheda madre


class DualSerialManager:
    """
    Classe per gestire la comunicazione seriale su due porte separate:
    - Porta dati: per lettura continua e comandi di lettura
    - Porta setup: per modificare configurazioni del dispositivo
    """

    def __init__(self,  # Metodo costruttore
                 data_port: str = '/dev/ttyUSB0',
                 setup_port: str = '/dev/ttyAMA10',
                 baudrate: int = 9600,  # baudrate standard, è possibile cambiarlo dalle impostazioni, possibile impostare un array con un metodo che controlla tutte le possibilli in modo tale che se cambiato possa adattarsi
                 timeout: float = 1.0): # Vorrei abbassarlo a 0.1 in quanto nei test precedenti era abbastanza per la lettura del dato intero ma possibile problema dovuto alla quantità di dati da ricevere
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

        # Thread per lettura continua - apro un thread che svolge un'ascolto continuo su ciò ch invia la seriale
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

        Questa funzione è studiata in modo tale che sia interscambiabile, non importa se devo aprire una connessione per
        il SETUP o per la PRINTER, uso sempre la stessa funzione di connessione.

        Args:
            port_type (PortType): Tipo di porta da connettere

        Returns:
            bool: True se connessione riuscita, False altrimenti
        """
        try:
            config = self.ports_config[port_type]

            # Chiudi connessione esistente se presente, si assicura che sia sempre presente la connessione,
            # quindi se quella porta è già aperta la chiude per poi riaprirla con la nuova connessione richiesta.
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
                time.sleep(0.1)  # Breve pausa per permettere al dispositivo di rispondere

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

    def send_setup_command(self, command: str) -> Optional[str]:
        """
        Invia un comando di setup sulla porta setup (/dev/ttyAMA10)

        Args:
            command (str): Comando di configurazione da inviare

        Returns:
            Optional[str]: Risposta ricevuta o None se errore
        """
        if not self.is_connected(PortType.SETUP_PORT):
            logger.error("Porta setup non connessa")
            return None

        try:
            with self.setup_lock:
                connection = self.ports_config[PortType.SETUP_PORT]['connection']

                # Pulisci buffer di input
                connection.flushInput()

                # Invia comando (aggiunge \r\n se non presente)
                if not command.endswith(('\r\n', '\n')):
                    command += '\r\n'

                connection.write(command.encode('utf-8'))
                logger.info(f"Comando setup inviato: {command.strip()}")

                # Attendi risposta
                time.sleep(0.2)  # Pausa più lunga per comandi di setup

                # Leggi risposta
                response = ""
                start_time = time.time()
                timeout = self.ports_config[PortType.SETUP_PORT]['timeout'] * 2  # Timeout maggiore per setup

                while time.time() - start_time < timeout:
                    if connection.in_waiting > 0:
                        data = connection.read(connection.in_waiting).decode('utf-8', errors='ignore')
                        response += data

                        # Se troviamo un terminatore, interrompi
                        if '\n' in response or '\r' in response:
                            break
                    time.sleep(0.01)

                response = response.strip()
                if response:
                    logger.info(f"Risposta comando setup: {response}")
                    return response
                else:
                    logger.warning("Nessuna risposta al comando di setup")
                    return None

        except Exception as e:
            logger.error(f"Errore invio comando setup: {e}")
            return None

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
                    # Progettato in modo tale che non analizzi il messaggio finche non è completo
                    # Rischio di problemi relativi al sovraccarico della CPU e/o saturazione della RAM in caso di eccessivo
                    # invio di dati o di invio di dati più lunghi/complessi

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

    # Esempio di parsing semplice
    if "TEMP:" in data:
        try:
            temp_str = data.split("TEMP:")[1].strip()
            temperature = float(temp_str)
            print(f"️  Temperatura rilevata: {temperature}°C")
        except (ValueError, IndexError):
            print("️  Formato temperatura non riconosciuto")


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
        print("\n" + "=" * 50)
        print("MENU COMANDI")
        print("=" * 50)
        print("1. Invia comando di lettura")
        print("2. Invia comando di setup")
        print("3. Mostra stato")
        print("4. Ferma/Avvia lettura continua")
        print("0. Esci")
        print("=" * 50)

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
                    command = input("Comando di setup: ").strip()
                    if command:
                        response = serial_manager.send_setup_command(command)
                        if response:
                            print(f" Risposta: {response}")
                        else:
                            print(" Nessuna risposta ricevuta")

                elif choice == '3':
                    print("\n Stato attuale:")
                    status = serial_manager.get_status()
                    for port_name, port_info in status.items():
                        if port_name == 'continuous_reading':
                            print(f"   Lettura continua: {'Attiva' if port_info else 'Inattiva'}")
                        else:
                            print(
                                f"   {port_info['port']}: {'Connessa' if port_info['connected'] else 'Disconnessa'} @ {port_info['baudrate']} baud")

                elif choice == '4':
                    if serial_manager.is_reading:
                        serial_manager.stop_continuous_reading()
                        print(" Lettura continua fermata")
                    else:
                        if serial_manager.is_connected(PortType.DATA_PORT):
                            serial_manager.start_continuous_reading(data_received_callback)
                            print("️  Lettura continua avviata")
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