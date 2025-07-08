#!/usr/bin/env python3
"""
Controller professionale per Dini Argeo 3590E collegata direttamente al Raspberry Pi
"""

import serial
import serial.tools.list_ports
import time
import threading
import sys
from datetime import datetime
import select
import re

class Controller3590E:
    def __init__(self):
        self.ser = None
        self.lettura_attiva = False
        self.thread_lettura = None
        self.thread_input = None
        self.dati_ricevuti = []
        
        # Parametri configurabili dal manuale 3590E
        self.parametri_setup = {
            "P01": {"nome": "Divisione", "valori": "1, 2, 5, 10, 20, 50", "descrizione": "Divisione di lettura"},
            "P02": {"nome": "Portata Max", "valori": "1-99999", "descrizione": "Portata massima bilancia"},
            "P03": {"nome": "Unità Misura", "valori": "1=kg, 2=g, 3=t, 4=lb", "descrizione": "Unità di misura peso"},
            "P04": {"nome": "Punto Decimale", "valori": "0-3", "descrizione": "Numero cifre decimali"},
            "P05": {"nome": "Protocollo Com", "valori": "0=Standard, 1=485", "descrizione": "Protocollo comunicazione"},
            "P06": {"nome": "Baud Rate", "valori": "0=2400, 1=4800, 2=9600, 3=19200", "descrizione": "Velocità comunicazione"},
            "P07": {"nome": "Trasmissione", "valori": "0=Manuale, 1=Auto, 2=Continua", "descrizione": "Modalità trasmissione dati"},
            "P08": {"nome": "Filtro", "valori": "0-3", "descrizione": "Livello filtro stabilità"},
            "P09": {"nome": "Zero Auto", "valori": "0=Off, 1=On", "descrizione": "Azzeramento automatico"},
            "P10": {"nome": "Tara Auto", "valori": "0=Off, 1=On", "descrizione": "Tara automatica"},
            "P11": {"nome": "Display Mode", "valori": "0=Normale, 1=Peak Hold", "descrizione": "Modalità display"},
            "P12": {"nome": "Standby", "valori": "0=Off, 1-30=min", "descrizione": "Timeout standby"},
            "P15": {"nome": "Password", "valori": "0000-9999", "descrizione": "Password accesso setup"},
        }
    
    def trova_porta_seriale(self):
        """Trova la porta seriale del Raspberry Pi"""
        #la porta che utilizza solitamente è la /dev/ttyAMA10 se collegato con i pin seriali, se collegato con l'adattatore USB è /dev/ttyUSB0
        #Nella nuova versione verranno utilizzate entrambe le porte contemporaneamente, una per la lettura e l'altra per l'invio di comandi
        #nelle funzioni di setup e modifica parametri
        porte_comuni = ['/dev/ttyAMA10', '/dev/ttyUSB0']
        
        print("Ricerca porta seriale...")
        
        # Prima controlla porte automatiche
        ports = list(serial.tools.list_ports.comports())
        if ports:
            for port in ports:
                print(f"Trovata: {port.device} - {port.description}")
                return port.device
        
        # Poi prova porte comuni Raspberry Pi
        for porta in porte_comuni:
            try:
                test_ser = serial.Serial(porta, 9600, timeout=0.1)
                test_ser.close()
                print(f"Porta disponibile: {porta}")
                return porta
            except:
                continue
        
        print("ERRORE: Nessuna porta seriale trovata")
        return None
    
    def connetti(self, porta=None, baudrate=9600):
        """Connessione alla bilancia"""
        if not porta:
            porta = self.trova_porta_seriale()
            if not porta:
                return False
        
        try:
            self.ser = serial.Serial(
                port=porta,
                baudrate=baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=1,
                rtscts=False,
                dsrdtr=False
            )
            print(f"Connesso a {porta} - {baudrate} baud")
            time.sleep(2)  # Attende stabilizzazione
            return True
        except Exception as e:
            print(f"ERRORE connessione: {e}")
            return False
    
    def estrai_peso_pulito(self, dato):
        """Estrae solo il peso pulito dal dato grezzo"""
        try:
            # Pattern 1: numero seguito da unità (es: "41,kg", "1234,g")
            pattern1 = r'(\d+(?:[,\.]\d+)?)\s*[,\s]*\s*(kg|g|t|lb)'
            match1 = re.search(pattern1, dato, re.IGNORECASE)
            
            if match1:
                valore = match1.group(1).replace(',', '.')
                unita = match1.group(2).lower()
                return f"{valore} {unita}"
            
            # Pattern 2: solo numero con virgola (es: "41,5")
            pattern2 = r'(\d+[,\.]\d+)'
            match2 = re.search(pattern2, dato)
            
            if match2:
                valore = match2.group(1).replace(',', '.')
                return f"{valore}"
            
            # Pattern 3: numero intero isolato
            pattern3 = r'\b(\d+)\b'
            match3 = re.search(pattern3, dato)
            
            if match3 and len(match3.group(1)) <= 6:  # Evita numeri troppo lunghi
                return match3.group(1)
            
            return None
            
        except Exception as e:
            return None
    
    def lettura_continua_worker(self):
        """Worker thread per lettura continua"""
        print("Lettura continua attivata")
        print("Premere 'q' + ENTER per fermare")
        print("-" * 40)
        
        ultima_riga_mostrata = ""
        contatore_duplicati = 0
        
        while self.lettura_attiva:
            try:
                if self.ser and self.ser.is_open:
                    bytes_disponibili = self.ser.in_waiting
                    
                    if bytes_disponibili > 0:
                        dati = self.ser.read(bytes_disponibili)
                        timestamp = datetime.now().strftime("%H:%M:%S")
                        
                        try:
                            # Decodifica dati
                            dati_str = dati.decode('ascii', errors='ignore').strip()
                            
                            if dati_str:
                                # Processa ogni riga
                                righe = dati_str.split('\n')
                                
                                for riga in righe:
                                    riga_pulita = riga.strip()
                                    if riga_pulita:
                                        # Estrae solo il peso pulito
                                        peso_pulito = self.estrai_peso_pulito(riga_pulita)
                                        
                                        if peso_pulito and peso_pulito != ultima_riga_mostrata:
                                            if contatore_duplicati > 0:
                                                contatore_duplicati = 0
                                            
                                            print(f"[{timestamp}] {peso_pulito}")
                                            ultima_riga_mostrata = peso_pulito
                                            
                                            # Salva nei dati ricevuti
                                            self.dati_ricevuti.append(f"{timestamp}: {peso_pulito}")
                                            
                                            # Mantieni solo ultimi 100 messaggi
                                            if len(self.dati_ricevuti) > 100:
                                                self.dati_ricevuti = self.dati_ricevuti[-100:]
                                        elif peso_pulito == ultima_riga_mostrata:
                                            contatore_duplicati += 1
                                            # Non stampa duplicati consecutivi
                                            
                        except Exception as decode_error:
                            pass  # Ignora errori di decodifica
                
                time.sleep(0.01)  # 10ms delay
                
            except Exception as e:
                if self.lettura_attiva:
                    print(f"ERRORE lettura: {e}")
                break
        
        print("Lettura continua terminata")
    
    def gestisci_input_lettura(self):
        """Gestisce input utente durante la lettura continua"""
        while self.lettura_attiva:
            try:
                # Controllo input non bloccante (funziona solo su Linux/Unix)
                import os
                if os.name == 'posix':
                    if select.select([sys.stdin], [], [], 0.1)[0]:
                        comando = sys.stdin.readline().strip().lower()
                        
                        if comando == 'q':
                            print("\nFermando lettura continua...")
                            self.ferma_lettura_continua()
                            break
                        elif comando:
                            # Invia comando personalizzato
                            self.invia_comando(comando.upper(), f"Comando: {comando}")
                else:
                    # Su Windows il select non funziona con stdin
                    time.sleep(0.1)
            except:
                time.sleep(0.1)
    
    def mostra_statistiche_lettura(self):
        """Mostra statistiche della lettura continua"""
        if self.dati_ricevuti:
            print(f"\nSTATISTICHE LETTURA:")
            print(f"   Messaggi ricevuti: {len(self.dati_ricevuti)}")
            print(f"   Ultimo messaggio: {self.dati_ricevuti[-1] if self.dati_ricevuti else 'Nessuno'}")
            print(f"   Primo messaggio: {self.dati_ricevuti[0] if self.dati_ricevuti else 'Nessuno'}")
        else:
            print("\nNessun dato ricevuto ancora")
    
    def avvia_lettura_continua(self):
        """Avvia lettura continua in thread separato"""
        if self.lettura_attiva:
            print("WARNING: Lettura già attiva")
            return
        
        if not self.ser:
            print("ERRORE: Connessione non attiva")
            return
        
        self.lettura_attiva = True
        self.thread_lettura = threading.Thread(target=self.lettura_continua_worker, daemon=True)
        self.thread_lettura.start()
        
        # Avvia anche il thread per input utente durante lettura
        self.thread_input = threading.Thread(target=self.gestisci_input_lettura, daemon=True)
        self.thread_input.start()
    
    def ferma_lettura_continua(self):
        """Ferma lettura continua"""
        if self.lettura_attiva:
            self.lettura_attiva = False
            if self.thread_lettura:
                self.thread_lettura.join(timeout=2)
            print("\nLettura continua fermata")
            print("Premere ENTER per tornare al menu...")
    
    def invia_comando(self, comando, descrizione=""):
        """Invia comando alla bilancia"""
        if not self.ser:
            print("ERRORE: Connessione non attiva")
            return None
        
        try:
            # Pulisce buffer input
            self.ser.reset_input_buffer()
            
            # Invia comando
            cmd_bytes = comando.encode('ascii') + b'\r\n'
            self.ser.write(cmd_bytes)
            
            if descrizione:
                print(f"INVIO {descrizione}: {comando}")
            else:
                print(f"INVIO comando: {comando}")
            
            # Attende risposta
            time.sleep(0.5)
            
            if self.ser.in_waiting > 0:
                risposta = self.ser.read(self.ser.in_waiting)
                try:
                    resp_str = risposta.decode('ascii', errors='ignore').strip()
                    print(f"RISPOSTA: {resp_str[:100]}...")
                    return resp_str
                except:
                    print(f"RISPOSTA raw: {risposta}")
                    return risposta
            else:
                print("Nessuna risposta")
                return None
                
        except Exception as e:
            print(f"ERRORE invio comando: {e}")
            return None
    
    def mostra_parametri_disponibili(self):
        """Mostra tutti i parametri configurabili"""
        print("\nPARAMETRI CONFIGURABILI 3590E")
        print("=" * 80)
        print(f"{'Param':<6} {'Nome':<15} {'Valori':<25} {'Descrizione'}")
        print("-" * 80)
        
        for param, info in self.parametri_setup.items():
            print(f"{param:<6} {info['nome']:<15} {info['valori']:<25} {info['descrizione']}")
        
        print("\nPer modificare un parametro: P[numero]=[valore]")
        print("   Esempio: P03=2 (cambia unità in grammi)")
    
    def modifica_parametro(self):
        """Interfaccia per modificare un parametro"""
        print("\nMODIFICA PARAMETRI BILANCIA")
        print("=" * 50)
        print("IMPORTANTE: Assicurarsi di essere in modalità SETUP sulla bilancia!")
        print("   • Accedere al SETUP fisicamente dalla bilancia")
        print("   • Oppure usare il comando SETUP se supportato via seriale")
        print()
        
        input("Premere ENTER quando si è in modalità SETUP...")
        
        self.mostra_parametri_disponibili()
        
        while True:
            print("\nOpzioni:")
            print("1. Modifica parametro specifico")
            print("2. Cambia unità da kg a grammi (P03=2)")
            print("3. Attiva trasmissione continua (P07=2)")
            print("4. Cambia velocità comunicazione")
            print("0. Torna al menu principale")
            
            scelta = input("\nScelta: ").strip()
            
            if scelta == "0":
                break
            elif scelta == "1":
                self.modifica_parametro_manuale()
            elif scelta == "2":
                self.cambia_unita_grammi()
            elif scelta == "3":
                self.attiva_trasmissione_continua()
            elif scelta == "4":
                self.cambia_baudrate()
            else:
                print("ERRORE: Scelta non valida")
    
    def modifica_parametro_manuale(self):
        """Modifica manuale di un parametro"""
        param = input("\nInserire parametro (es. P03): ").strip().upper()
        
        if param in self.parametri_setup:
            info = self.parametri_setup[param]
            print(f"\n{param} - {info['nome']}")
            print(f"   Valori possibili: {info['valori']}")
            print(f"   Descrizione: {info['descrizione']}")
            
            valore = input(f"\nInserire nuovo valore per {param}: ").strip()
            
            if valore:
                comando = f"{param}={valore}"
                self.invia_comando(comando, f"Modifica {param}")
                
                # Prova a salvare
                self.invia_comando("SAVE", "Salvataggio configurazione")
            else:
                print("ERRORE: Valore non valido")
        else:
            print(f"ERRORE: Parametro {param} non riconosciuto")
    
    def cambia_unita_grammi(self):
        """Cambia unità di misura in grammi"""
        print("\nCambio unità di misura: KG -> GRAMMI")
        
        conferma = input("Confermare di essere in modalità SETUP? (s/n): ").strip().lower()
        if conferma not in ['s', 'si', 'sì', 'y', 'yes']:
            print("Operazione annullata")
            return
        
        # Sequenza comandi per grammi
        comandi = [
            ("P03=2", "Imposta unità grammi"),
            ("SAVE", "Salva configurazione"),
        ]
        
        for comando, desc in comandi:
            risposta = self.invia_comando(comando, desc)
            time.sleep(1)
            
            if risposta and 'ERR' in risposta:
                print(f"ERRORE: {risposta}")
                return
        
        print("Unità cambiata in grammi")
        print("Uscire dalla modalità SETUP per applicare le modifiche")
    
    def attiva_trasmissione_continua(self):
        """Attiva trasmissione continua dei dati"""
        print("\nAttivazione trasmissione continua")
        
        self.invia_comando("P07=2", "Trasmissione continua")
        self.invia_comando("SAVE", "Salva configurazione")
        
        print("Trasmissione continua attivata")
    
    def cambia_baudrate(self):
        """Cambia velocità di comunicazione"""
        print("\nCambio velocità comunicazione")
        print("0 = 2400 baud")
        print("1 = 4800 baud") 
        print("2 = 9600 baud")
        print("3 = 19200 baud")
        
        scelta = input("\nScegliere velocità (0-3): ").strip()
        
        if scelta in ['0', '1', '2', '3']:
            self.invia_comando(f"P06={scelta}", "Cambio baud rate")
            self.invia_comando("SAVE", "Salva configurazione")
            print("Velocità cambiata")
            print("Riavviare la connessione con la nuova velocità")
        else:
            print("ERRORE: Scelta non valida")
    
    def leggi_parametro_specifico(self):
        """Legge un parametro specifico"""
        print("\nLETTURA PARAMETRO SPECIFICO")
        print("=" * 40)
        
        self.mostra_parametri_disponibili()
        
        param = input("\nInserire parametro da leggere (es. P03): ").strip().upper()
        
        if param in self.parametri_setup:
            # Prova diversi comandi per leggere il parametro
            comandi_lettura = [
                f"{param}?",
                f"GET {param}",
                f"READ {param}",
                f"SHOW {param}",
                param,
            ]
            
            for comando in comandi_lettura:
                print(f"\nTentativo lettura con: {comando}")
                risposta = self.invia_comando(comando, f"Lettura {param}")
                
                if risposta and 'ERR' not in risposta:
                    print(f"Valore {param}: {risposta}")
                    return
            
            print(f"Impossibile leggere {param}")
            print("Provare ad accedere alla modalità SETUP")
        else:
            print(f"ERRORE: Parametro {param} non riconosciuto")
    
    def test_comunicazione_avanzato(self):
        """Test comunicazione avanzato con debug"""
        print("\nTEST COMUNICAZIONE AVANZATO")
        print("=" * 50)
        
        if not self.ser:
            print("ERRORE: Nessuna connessione attiva")
            return
        
        print(f"Porta: {self.ser.port}")
        print(f"Baud rate: {self.ser.baudrate}")
        print(f"Porta aperta: {self.ser.is_open}")
        print(f"Timeout: {self.ser.timeout}")
        
        # Test 1: Lettura immediata
        print(f"\nTest 1: Bytes disponibili immediatamente")
        bytes_immediati = self.ser.in_waiting
        print(f"   Bytes in coda: {bytes_immediati}")
        
        if bytes_immediati > 0:
            dati_immediati = self.ser.read(bytes_immediati)
            print(f"   Dati letti: {dati_immediati}")
            print(f"   Hex: {dati_immediati.hex()}")
        
        # Test 2: Attesa dati per 5 secondi
        print(f"\nTest 2: Attesa dati per 5 secondi...")
        for i in range(50):  # 5 secondi
            bytes_attesa = self.ser.in_waiting
            if bytes_attesa > 0:
                dati_attesa = self.ser.read(bytes_attesa)
                print(f"   [{i*0.1:.1f}s] Ricevuti {len(dati_attesa)} bytes: {dati_attesa}")
                print(f"   Hex: {dati_attesa.hex()}")
            time.sleep(0.1)
        
        # Test 3: Invio comandi base
        print(f"\nTest 3: Invio comandi di test")
        comandi_test = [
            ("", "Comando vuoto"),
            ("W", "Richiesta peso"),
            ("INFO", "Informazioni"),
            ("STATUS", "Status"),
            ("?", "Help"),
        ]
        
        for comando, desc in comandi_test:
            print(f"\nTest comando: '{comando}' ({desc})")
            self.ser.reset_input_buffer()
            
            # Invia comando
            if comando:
                self.ser.write(comando.encode('ascii') + b'\r\n')
                print(f"   Inviato: {repr(comando + chr(13) + chr(10))}")
            else:
                self.ser.write(b'\r\n')
                print(f"   Inviato: solo CR+LF")
            
            # Attende risposta
            time.sleep(1)
            bytes_risposta = self.ser.in_waiting
            print(f"   Bytes risposta: {bytes_risposta}")
            
            if bytes_risposta > 0:
                risposta = self.ser.read(bytes_risposta)
                print(f"   Risposta raw: {risposta}")
                print(f"   Risposta hex: {risposta.hex()}")
                try:
                    resp_ascii = risposta.decode('ascii', errors='ignore')
                    print(f"   Risposta ASCII: {repr(resp_ascii)}")
                except:
                    print(f"   Errore decodifica ASCII")
            else:
                print(f"   Nessuna risposta")
        
        print(f"\nTest comunicazione completato")
    
    def mostra_ultimi_dati(self):
        """Mostra gli ultimi dati ricevuti"""
        print("\nULTIMI DATI RICEVUTI")
        print("=" * 50)
        
        if not self.dati_ricevuti:
            print("Nessun dato ricevuto ancora")
            return
        
        # Mostra ultimi 20 messaggi
        ultimi = self.dati_ricevuti[-20:]
        for i, dato in enumerate(ultimi, 1):
            print(f"{i:2d}. {dato}")
        
        print(f"\nTotale messaggi: {len(self.dati_ricevuti)}")
        
        # Salva su file se richiesto
        salva = input("\nSalvare tutti i dati su file? (s/n): ").strip().lower()
        if salva in ['s', 'si', 'sì', 'y', 'yes']:
            filename = f"dati_bilancia_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
            try:
                with open(filename, 'w') as f:
                    f.write(f"Dati Bilancia 3590E - {datetime.now()}\n")
                    f.write("=" * 50 + "\n\n")
                    for dato in self.dati_ricevuti:
                        f.write(f"{dato}\n")
                print(f"Dati salvati in: {filename}")
            except Exception as e:
                print(f"ERRORE salvataggio: {e}")
    
    def configura_connessione(self):
        """Configurazione parametri connessione"""
        print("\nCONFIGURAZIONE CONNESSIONE")
        print("=" * 40)
        
        if self.ser:
            self.ser.close()
            self.ferma_lettura_continua()
        
        porta = input("Porta seriale [auto]: ").strip()
        if not porta:
            porta = None
        
        try:
            baudrate = input("Baud rate [9600]: ").strip()
            baudrate = int(baudrate) if baudrate else 9600
        except:
            baudrate = 9600
        
        if self.connetti(porta, baudrate):
            print("Riconnesso con nuovi parametri")
        else:
            print("ERRORE riconnessione")
    
    def test_veloce_lettura(self):
        """Test veloce per vedere se arrivano dati"""
        print("\nTEST VELOCE LETTURA PORTA")
        print("=" * 40)
        print("Monitoraggio per 10 secondi...")
        
        if not self.ser:
            print("ERRORE: Nessuna connessione")
            return
        
        print(f"Porta: {self.ser.port}")
        print(f"Stato: {'Aperta' if self.ser.is_open else 'Chiusa'}")
        
        for i in range(100):  # 10 secondi
            try:
                bytes_disp = self.ser.in_waiting
                if bytes_disp > 0:
                    dati = self.ser.read(bytes_disp)
                    print(f"[{i/10:.1f}s] {len(dati)} bytes: {dati}")
                    print(f"      HEX: {dati.hex()}")
                    try:
                        ascii_data = dati.decode('ascii', errors='ignore')
                        print(f"      ASCII: {repr(ascii_data)}")
                    except:
                        pass
                else:
                    if i % 10 == 0:  # Ogni secondo
                        print(f"[{i/10:.1f}s] Nessun dato")
                
                time.sleep(0.1)
            except Exception as e:
                print(f"ERRORE: {e}")
                break
        
        print("Test completato")
    
    def menu_principale(self):
        """Menu principale dell'applicazione"""
        while True:
            print("\n" + "=" * 60)
            print("CONTROLLER BILANCIA DINI ARGEO 3590E")
            print("=" * 60)
            print("1. Lettura continua dati (q=ferma)")
            print("2. Modifica parametri configurazione")
            print("3. Leggi parametro specifico")
            print("4. Test comunicazione avanzato")
            print("5. Mostra parametri disponibili")
            print("6. Configurazione connessione")
            print("7. Mostra ultimi dati ricevuti")
            print("8. Test veloce lettura porta")
            print("0. Esci")
            
            if self.lettura_attiva:
                print("\nLettura continua ATTIVA - Premere 's' per fermare")
            
            scelta = input("\nScelta: ").strip()
            
            if scelta == "0":
                self.ferma_lettura_continua()
                if self.ser:
                    self.ser.close()
                print("Programma terminato")
                break
            elif scelta == "1":
                if self.lettura_attiva:
                    self.ferma_lettura_continua()
                else:
                    self.avvia_lettura_continua()
            elif scelta == "2":
                self.modifica_parametro()
            elif scelta == "3":
                self.leggi_parametro_specifico()
            elif scelta == "4":
                self.test_comunicazione_avanzato()
            elif scelta == "5":
                self.mostra_parametri_disponibili()
            elif scelta == "6":
                self.configura_connessione()
            elif scelta == "7":
                self.mostra_ultimi_dati()
            elif scelta == "8":
                self.test_veloce_lettura()
            elif scelta.lower() == "s" and self.lettura_attiva:
                self.ferma_lettura_continua()
            else:
                print("ERRORE: Scelta non valida")

def main():
    print("AVVIO CONTROLLER BILANCIA 3590E")
    print("=" * 50)
    
    controller = Controller3590E()
    
    try:
        # Connessione iniziale
        if controller.connetti():
            controller.menu_principale()
        else:
            print("ERRORE: Impossibile connettersi alla bilancia")
            
    except KeyboardInterrupt:
        print("\nProgramma interrotto")
    finally:
        controller.ferma_lettura_continua()
        if controller.ser:
            controller.ser.close()

if __name__ == "__main__":
    main()