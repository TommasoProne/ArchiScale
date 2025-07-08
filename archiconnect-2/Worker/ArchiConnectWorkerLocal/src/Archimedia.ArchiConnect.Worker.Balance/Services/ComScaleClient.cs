using System.IO.Ports;
using System.Text;
using Archimedia.ArchiConnect.Worker.Balance.Models;

namespace Archimedia.ArchiConnect.Worker.Balance.Services;

/// <summary>
///     Client per la comunicazione con bilance attraverso una porta seriale COM.
///     Gestisce la connessione, la lettura dei dati e la riconnessione automatica.
/// </summary>
public class COMScaleClient : IDisposable
{
    private readonly string _portName;
    private readonly int _baudRate;
    private readonly string _inputMask;
    private readonly string _scaleName;
    private readonly string _scaleDescription;

    private SerialPort? _serialPort;
    private readonly StringBuilder _dataBuffer = new();
    private bool _isConnected;
    private readonly CancellationTokenSource _cancellationTokenSource = new();
    private Task? _readTask;

    /// <summary>
    ///     Evento che verrà scatenato quando arrivano i dati.
    /// </summary>
    public event EventHandler<PesataDto>? DataReceived;

    /// <summary>
    ///     Inizializza una nuova istanza della classe <see cref="COMScaleClient" />.
    /// </summary>
    /// <param name="portName">Nome della porta COM (es. "COM1").</param>
    /// <param name="baudRate">Velocità in baud della porta seriale.</param>
    /// <param name="inputMask">Formato dei dati ricevuti dalla bilancia.</param>
    /// <param name="scaleName">Nome della bilancia.</param>
    /// <param name="scaleDescription">Descrizione della bilancia.</param>
    /// <param name="dataBits">Numero di bit di dati (default 8).</param>
    /// <param name="parity">Parità (default None).</param>
    /// <param name="stopBits">Bit di stop (default One).</param>
    /// <param name="handshake">Controllo di flusso (default None).</param>
    public COMScaleClient(
        string portName,
        int baudRate,
        string inputMask,
        string scaleName,
        string scaleDescription,
        int dataBits = 8,
        Parity parity = Parity.None,
        StopBits stopBits = StopBits.One,
        Handshake handshake = Handshake.None)
    {
        _portName = portName;
        _baudRate = baudRate;
        _inputMask = inputMask;
        _scaleName = scaleName;
        _scaleDescription = scaleDescription;

        _serialPort = new SerialPort
        {
            PortName = portName,
            BaudRate = baudRate,
            DataBits = dataBits,
            Parity = parity,
            StopBits = stopBits,
            Handshake = handshake,
            ReadTimeout = 500,
            WriteTimeout = 500
        };
    }

    /// <summary>
    ///     Indica se il client è attualmente connesso alla porta seriale.
    /// </summary>
    public bool IsConnected => _isConnected && _serialPort?.IsOpen == true;

    /// <summary>
    ///     Stabilisce una connessione con la bilancia tramite la porta seriale specificata.
    /// </summary>
    public void Connect()
    {
        if (IsConnected) return;

        try
        {
            if (_serialPort == null)
            {
                _serialPort = new SerialPort
                {
                    PortName = "/dev/ttyAMA10",
                    BaudRate = 9600,
                    DataBits = 8,
                    Parity = Parity.None,
                    StopBits = StopBits.One,
                    ReadTimeout = 500,
                    WriteTimeout = 500
                };
            }

            // Chiudo la connessione se già aperta e la riapro
            if (_serialPort.IsOpen && _isConnected == true)
            {
                _serialPort.Close();
                _isConnected = false;
                Thread.Sleep(100);
                _serialPort.Open();
                _isConnected = true;

                // Avvia un task separato per la lettura continua
                _readTask = Task.Run(ReadDataContinuously, _cancellationTokenSource.Token);

                Console.WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss} - Bilancia {_portName} '{_scaleName}' ({_scaleDescription}) connessa.");
            }
            else
            {
                _serialPort.Open();
                _isConnected = true;
                
                // Avvia un task separato per la lettura continua
                _readTask = Task.Run(ReadDataContinuously, _cancellationTokenSource.Token);

                Console.WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss} - Bilancia {_portName} '{_scaleName}' ({_scaleDescription}) connessa.");
            }
        }
        catch (Exception e)
        {
            _isConnected = false;
            Console.WriteLine(
                $"{DateTime.Now:dd/MM/yyyy HH:mm:ss} - Errore durante la connessione alla porta '{_portName}':\n{e.Message}");
        }
    }

    /// <summary>
    ///     Chiude la connessione con la porta seriale e rilascia le risorse.
    /// </summary>
    public void Disconnect()
    {
        try
        {
            // Ferma il task di lettura
            _cancellationTokenSource.Cancel();

            if (_serialPort?.IsOpen == true)
            {
                _serialPort.Close();
                Console.WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss} - Bilancia {_portName} disconnessa.");
            }

            _isConnected = false;
        }
        catch (Exception e)
        {
            Console.WriteLine($"Errore durante la disconnessione dalla porta {_portName}: {e.Message}");
        }
    }

    /// <summary>
    ///     Legge continuamente i dati dalla porta seriale in un ciclo separato.
    /// </summary>
    private async Task ReadDataContinuously()
    {
        while (!_cancellationTokenSource.Token.IsCancellationRequested && _serialPort?.IsOpen == true)
        {
            try
            {
                // Legge i dati disponibili
                if (_serialPort.BytesToRead > 0)
                {
                    var buffer = new byte[_serialPort.BytesToRead];
                    var bytesRead = _serialPort.Read(buffer, 0, buffer.Length);

                    if (bytesRead > 0)
                    {
                        var receivedData = Encoding.ASCII.GetString(buffer, 0, bytesRead);
                        _dataBuffer.Append(receivedData);

                        // Elabora i messaggi completi nel buffer
                        ProcessDataBuffer();
                    }
                }

                // Attesa breve per ridurre il carico della CPU
                await Task.Delay(50, _cancellationTokenSource.Token);
            }
            catch (OperationCanceledException)
            {
                break; // Interruzione normale quando viene richiesta la cancellazione
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Errore durante la lettura dalla porta {_portName}: {ex.Message}");

                // Tenta di riconnettere in caso di errore di lettura
                TryReconnect();

                // Breve attesa prima di riprovare
                await Task.Delay(1000, _cancellationTokenSource.Token);
            }
        }
    }

    /// <summary>
    ///     Tenta di riconnettere la porta seriale in caso di errore.
    /// </summary>
    private void TryReconnect()
    {
        try
        {
            if (_serialPort?.IsOpen == true)
            {
                _serialPort.Close();
                _isConnected = false;
            }

            // Attendiamo un attimo prima di tentare la riconnessione
            Thread.Sleep(500);

            // Riapri la porta
            if (_serialPort != null && !_serialPort.IsOpen)
            {
                _serialPort.Open();
                _isConnected = true;
                Console.WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss} - Riconnessione a {_portName} riuscita.");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Tentativo di riconnessione a {_portName} fallito: {ex.Message}");
            _isConnected = false;
        }
    }

    /// <summary>
    ///     Elabora il buffer di dati per estrarre messaggi completi.
    /// </summary>
    private void ProcessDataBuffer()
    {
        var content = _dataBuffer.ToString();

        if (string.IsNullOrEmpty(content))
            return;

        try
        {
            // Per i messaggi Sartorius, cerchiamo il pattern di due righe di trattini alla fine
            if (_inputMask.Equals("sartorius", StringComparison.OrdinalIgnoreCase))
            {
                // Verifichiamo se abbiamo ricevuto un messaggio Sartorius completo
                if (!StringDecoder.IsSartoriusMessageComplete(content)) return;

                // Processa il messaggio completo
                ProcessMessage(content);
                // Svuota il buffer
                _dataBuffer.Clear();
            }
            // Per gli altri tipi di messaggi, usiamo l'approccio basato sui terminatori
            else
            {
                while (!string.IsNullOrEmpty(content))
                {
                    // Identifica il messaggio completo in base al terminatore
                    var endMessageIndex = StringDecoder.FindMessageTerminator(content);

                    if (endMessageIndex == -1)
                        break; // Nessun messaggio completo trovato

                    // Estrae il messaggio completo
                    var completeMessage = content[..(endMessageIndex + 1)];
                    _dataBuffer.Remove(0, endMessageIndex + 1);
                    content = _dataBuffer.ToString();

                    // Passa il messaggio al metodo di processamento
                    ProcessMessage(completeMessage.Trim());
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] Errore nell'elaborazione del messaggio: {ex.Message}");
            // In caso di errore, svuotiamo il buffer per evitare accumuli problematici
            _dataBuffer.Clear();
        }
    }

    /// <summary>
    ///     Elabora un messaggio completo ricevuto dalla bilancia.
    /// </summary>
    /// <param name="message">Il messaggio completo da elaborare.</param>
    private void ProcessMessage(string message)
    {
        try
        {
            Console.WriteLine(new string('-', 50));
            Console.WriteLine($"[INFO] {DateTime.Now:dd/MM/yyyy HH:mm:ss} - Messaggio ricevuto:\n{message}");
            Console.WriteLine($"[INFO] InputMask corrente: {_inputMask}.");

            var pesata = new PesataDto
            {
                DataPesata = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            PesataDto? risultato;

            // Determina il formato del messaggio in base all'inputMask e al contenuto
            if (StringDecoder.ItalianaMacchiString(message))
            {
                Console.WriteLine("[INFO] Rilevato messaggio in formato Italiana Macchi.");
                risultato = StringDecoder.GetDataFromItalianaMacchi(message, pesata, _inputMask);
            }
            else if (_inputMask.Equals("sartorius", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine("[INFO] Rilevato messaggio in formato Sartorius.");
                risultato = StringDecoder.GetDataFromSartorius(message, pesata);
            }
            else
            {
                Console.WriteLine("[INFO] Provando a interpretare il messaggio come Dini Argeo.");
                risultato = StringDecoder.GetDataFromDiniArgeo(message, pesata, _inputMask);
            }

            // Verifica che il risultato sia valido
            if (risultato == null)
            {
                Console.WriteLine("[WARNING] Impossibile elaborare il messaggio in nessun formato noto.");
                return;
            }

            // Verifica che contenga almeno un valore di peso
            switch (risultato.PesoNetto)
            {
                case 0 when risultato is { PesoLordo: 0, PesoTara: 0 }:
                    Console.WriteLine("[WARNING] La pesata elaborata non contiene valori di peso validi.");
                    return;
                case 0 when risultato is { PesoLordo: > 0, PesoTara: > 0 }:
                    risultato.PesoNetto = risultato.PesoLordo - risultato.PesoTara;
                    break;
            }

            if (risultato is { PesoLordo: 0, PesoNetto: > 0, PesoTara: > 0 })
                risultato.PesoLordo = risultato.PesoNetto + risultato.PesoTara;

            if (risultato is { PesoTara: 0, PesoLordo: > 0, PesoNetto: > 0 })
                risultato.PesoTara = risultato.PesoLordo - risultato.PesoNetto;

            // Log della pesata elaborata
            Console.WriteLine(
                $"[INFO] Pesata elaborata correttamente: Netto={risultato.PesoNetto}, Tara={risultato.PesoTara}, Lordo={risultato.PesoLordo}");

            // Invia il messaggio elaborato
            OnDataReceived(risultato);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERRORE] Si è verificato un errore durante l'elaborazione del messaggio: {ex.Message}");
            Console.WriteLine($"[DEBUG] StackTrace: {ex.StackTrace}.");
        }
    }

    /// <summary>
    ///     Invia un messaggio alla bilancia tramite la porta seriale.
    /// </summary>
    /// <param name="message">Il messaggio da inviare.</param>
    public void SendMessage(string message)
    {
        if (!IsConnected) return;

        try
        {
            var data = Encoding.ASCII.GetBytes(message);
            _serialPort?.Write(data, 0, data.Length);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Errore durante l'invio del messaggio alla porta {_portName}: {ex.Message}");
        }
    }

    /// <summary>
    ///     Metodo per scatenare l'evento DataReceived.
    /// </summary>
    private void OnDataReceived(PesataDto data)
    {
        DataReceived?.Invoke(this, data);
    }

    /// <summary>
    ///     Rilascia le risorse utilizzate dalla classe.
    /// </summary>
    public void Dispose()
    {
        Disconnect();
        _cancellationTokenSource.Dispose();
        _serialPort?.Dispose();
        GC.SuppressFinalize(this);
    }
    
    public bool CheckConnection()
    {
        
    }
}