using Archimedia.ArchiConnect.Worker.Balance.Interfaces;
using Archimedia.ArchiConnect.Worker.Balance.Models;
using Archimedia.ArchiConnect.Worker.Balance.Services;
using Archimedia.ArchiConnect.Worker.Service.Interfaces;
using Archimedia.ArchiConnect.Worker.Shared.Helpers;
using Archimedia.ArchiConnect.Worker.Shared.Models;
using Microsoft.Extensions.Options;
using System;
using System.IO.Ports;

namespace Archimedia.ArchiConnect.Worker.BalanceService;

public class WorkerBalance(
    IBalanceClientService balanceClientService,
    IOrdiniService ordiniService,
    IRisorseService risorseService,
    IOptions<WorkerSettings> settings) : BackgroundService
{
    private readonly Dictionary<string, TcpBalanceClient> _balanceClients = new();
    private readonly Dictionary<string, OpcUaBalanceClient> _opcUaClients = new();
    private readonly WorkerSettings _settings = settings.Value;

    /// <summary>
    ///     Esegue il ciclo operativo del worker per la gestione della bilancia.
    /// </summary>
    /// <param name="stoppingToken">
    ///     Un <see cref="CancellationToken" /> utilizzato per monitorare e gestire
    ///     la richiesta di interruzione del processo.
    /// </param>
    /// <returns>
    ///     Un <see cref="Task" /> rappresentante l'operazione asincrona del metodo.
    /// </returns>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await InitDictionary(stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckConnection();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{DateTime.UtcNow} - {ex.Message}. {ex.StackTrace}");
            }

            await Task.Delay(_settings.WorkerRefreshTime * 1000, stoppingToken);
        }
    }

    public override Task StopAsync(CancellationToken stoppingToken)
    {
        // Chiudi tutte le connessioni OPC UA
        foreach (var client in _opcUaClients.Values)
            try
            {
                client.Disconnect();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Errore durante la disconnessione del client OPC UA: {ex.Message}");
            }

        return Task.CompletedTask;
    }

    /// <summary>
    ///     Inizializza i dizionari dei client associati alle bilance, creando una configurazione
    ///     necessaria per stabilire connessioni ai dispositivi configurati.
    /// </summary>
    /// <param name="cancellationToken">
    ///     Un <see cref="CancellationToken" /> utilizzato per monitorare e gestire
    ///     la richiesta di interruzione del processo.
    /// </param>
    /// <param name="maxRetries">
    ///     Numero massimo di tentativi consentiti per l'inizializzazione in caso di errore.
    /// </param>
    /// <returns>
    ///     Un <see cref="Task" /> che rappresenta l'operazione asincrona per l'inizializzazione.
    /// </returns>
    private async Task InitDictionary(CancellationToken cancellationToken, int maxRetries = 3)
    {
        var retryCount = 0;
        while (retryCount < maxRetries)
            try
            {
                if (_settings.OrganizzazioneId <= 0 || _settings.RisorsaId <= 0)
                    throw new ArgumentException("OrganizzazioneId e RisorsaId devono essere validi");

                // Gli indicatori sono gli apparecchi che collegano le pese.
                var indicatori = await ordiniService.GetRisorseChild(
                    _settings.OrganizzazioneId,
                    _settings.RisorsaId);

                var indicatoriFiltrati = indicatori.Results
                    .Where(b => b.TipoRisorsa == 3 && !string.IsNullOrEmpty(b.IndirizzoIp));

                foreach (var scale in indicatoriFiltrati)
                {
                    if (cancellationToken.IsCancellationRequested) break;

                    try
                    {
                        if (IsScaleValid(scale))
                            switch (scale.Formato)
                            {
                                case "ETH_DINI":
                                    InitializeTcpScale(scale);
                                    break;
                                case "OPCUA":
                                    InitializeOpcUaScale(scale);
                                    break;
                            }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(
                            $"Errore durante l'inizializzazione della bilancia '{scale.Codice}': {ex.Message}");
                    }
                }

                Console.WriteLine(
                    $"Inizializzazione completata. Bilance attive: {_balanceClients.Count + _opcUaClients.Count}");
                return;
            }
            catch (Exception ex)
            {
                retryCount++;
                Console.WriteLine(
                    $"Tentativo {retryCount}/{maxRetries} - Errore durante l'inizializzazione del dizionario");

                if (retryCount >= maxRetries)
                    throw new ApplicationException("Superato il numero massimo di tentativi di inizializzazione", ex);

                await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, retryCount)), cancellationToken);
            }
    }

    /// <summary>
    ///     Verifica se una bilancia è valida in base alla sua presenza nel dizionario dei client bilancia.
    /// </summary>
    /// <param name="scale">
    ///     Un oggetto di tipo <see cref="RisorsaDto" /> rappresentante le informazioni della bilancia da validare.
    /// </param>
    /// <returns>
    ///     Un valore booleano: <c>true</c> se la bilancia è valida (non presente nel dizionario),
    ///     altrimenti <c>false</c>.
    /// </returns>
    private bool IsScaleValid(RisorsaDto scale)
    {
        if (!_balanceClients.ContainsKey(scale.Codice)) return true;

        Console.WriteLine(
            $"Attenzione: Bilancia con codice '{scale.Codice}' già presente nel dizionario. Verrà ignorata.");
        return false;
    }

    /// <summary>
    ///     Inizializza una bilancia di tipo TCP utilizzando i parametri specificati
    ///     nella risorsa e configura un evento per gestire i dati ricevuti.
    /// </summary>
    /// <param name="risorsa">
    ///     Un'istanza di <see cref="RisorsaDto" /> che rappresenta la bilancia da inizializzare,
    ///     comprendente il codice, l'indirizzo IP, la descrizione e altri parametri utili.
    /// </param>
    private void InitializeTcpScale(RisorsaDto risorsa)
    {
        if (string.IsNullOrEmpty(risorsa.InputMask))
        {
            Console.WriteLine(
                $"Attenzione: Bilancia con codice '{risorsa.Codice}' non ha l'inputMask. Verrà ignorata.");
            return;
        }

        _balanceClients.Add(risorsa.Codice,
            new TcpBalanceClient(risorsa.IndirizzoIp, 23, risorsa.InputMask, risorsa.Codice, risorsa.Descrizione));

        _balanceClients[risorsa.Codice].DataReceived += async (_, data) =>
        {
            try
            {
                CompleteScaleData(data, risorsa);
                ShowPesataDto(data);
                await balanceClientService.PostPesata(data);
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    $"Errore durante l'elaborazione dei dati ricevuti dalla bilancia '{risorsa.Codice}': {ex.Message}");
            }
        };

        Console.WriteLine(
            $"{"Bilancia TCP",-15} '{risorsa.Codice}' ({risorsa.Descrizione + ")",-60} inizializzata correttamente.");
    }

    /// <summary>
    ///     Inizializza una bilancia di tipo OPC UA e registra gli eventi necessari per la comunicazione.
    /// </summary>
    /// <param name="risorsa">
    ///     Un'istanza di <see cref="RisorsaDto" /> contenente i dati della bilancia,
    ///     come codice, indirizzo IP e altre informazioni necessarie per la configurazione e la comunicazione.
    /// </param>
    private void InitializeOpcUaScale(RisorsaDto risorsa)
    {
        if (string.IsNullOrEmpty(risorsa.IndirizzoIp))
        {
            Console.WriteLine(
                $"Attenzione: Bilancia con codice '{risorsa.Codice}' non ha un indirizzo valido. Verrà ignorata.");
            return;
        }

        if (string.IsNullOrEmpty(risorsa.PrinterApiUrl))
        {
            Console.WriteLine(
                $"Attenzione: Bilancia con codice '{risorsa.Codice}' non ha l'indirizzo API Printer valido. Verrà ignorata.");
            return;
        }

        var risorsaTracciato = RecuperaTracciatiLettura(risorsa).GetAwaiter().GetResult();

        var endpointUrl =
            $"opc.tcp://{risorsa.IndirizzoIp}"; // TODO: In GLT la porta è 63840. Da aggiungere nella configurazione della risorsa.
        _opcUaClients.Add(risorsa.Codice,
            new OpcUaBalanceClient(endpointUrl, risorsa.Codice, risorsa.Descrizione, risorsa.IndirizzoIp, risorsaTracciato));

        _opcUaClients[risorsa.Codice].DataReceived += async (_, data) =>
        {
            try
            {
                CompleteScaleData(data, risorsa);
                ShowPesataDto(data);
                // await balanceClientService.InviaDatiPerEtichetta(data, risorsa.PrinterApiUrl, data.Codice, data.OrganizzazioneId);
                // return; // TODO: togliere questa riga e quella sopra prima di pubblicare.
                var result = await balanceClientService.PostPesata(data);

                if (result is null) return;
                await balanceClientService.InviaDatiPerEtichetta(data, risorsa.PrinterApiUrl, data.Codice,
                    data.OrganizzazioneId);
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    $"Errore durante l'elaborazione dei dati ricevuti dalla bilancia '{risorsa.Codice}': {ex.Message}");
            }
        };

        Console.WriteLine(
            $"Bilancia OPC UA '{risorsa.Codice}' ({risorsa.Descrizione + ")",-60} inizializzata correttamente.");
    }

    /// <summary>
    ///     Recupera i tracciati di lettura associati alla risorsa specificata.
    /// </summary>
    /// <param name="risorsa">
    ///     Un'istanza di <see cref="RisorsaDto" /> che rappresenta la risorsa per la quale
    ///     devono essere recuperati i tracciati di lettura.
    /// </param>
    /// <returns>
    ///     Una lista di oggetti <see cref="RisorsaTracciatoDto" /> che rappresentano i tracciati di lettura
    ///     associati alla risorsa specificata, oppure <c>null</c> se nessun tracciato è stato trovato.
    /// </returns>
    private async Task<List<RisorsaTracciatoDto>?> RecuperaTracciatiLettura(RisorsaDto risorsa)
    {
        try
        {
            var tracciati = await risorseService.GetTracciatiOfRisorsa(risorsa.OrganizzazioneId!.Value, risorsa.Codice);
            if (tracciati is null || tracciati.TotalCount == 0)
                return null;

            var tracciatiRead = tracciati.Results.Where(t => t.TracciatoType == TracciatoTypes.Lettura);
            var risorsaTracciatoDtos = tracciatiRead.ToList();
            foreach (var tracciatiRisorsa in risorsaTracciatoDtos)
            {
                if (tracciatiRisorsa.Tracciato is null)
                    continue;

                // Ottiene fields
                var fields = await risorseService.GetFieldsOfTracciati(tracciatiRisorsa.TracciatoId);
                if (fields is null || fields.HasErrors || fields.TotalCount == 0)
                    continue;

                tracciatiRisorsa.Tracciato.Fields = fields.Results;
            }

            return risorsaTracciatoDtos.ToList();
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"Errore durante il recupero dei tracciati per la risorsa '{risorsa.Codice}': {ex.Message}");
        }

        return [];
    }

    /// <summary>
    ///     Completa i dati di una pesata utilizzando le informazioni fornite dalla risorsa associata.
    /// </summary>
    /// <param name="data">
    ///     Un oggetto di tipo <see cref="PesataDto" /> che rappresenta i dati parziali o incompleti
    ///     di una pesata.
    /// </param>
    /// <param name="scale">
    ///     Un oggetto di tipo <see cref="RisorsaDto" /> contenente le informazioni della risorsa
    ///     (ad esempio, la bilancia) da cui completare i dati della pesata.
    /// </param>
    private static void CompleteScaleData(PesataDto? data, RisorsaDto scale)
    {
        if (data == null || scale.OrganizzazioneId == null) return;

        data.OrganizzazioneId = (int)scale.OrganizzazioneId;
        data.Id = scale.Id; // In realtà è un progressivo che viene incrementato automaticamente.
        data.Codice = scale.Codice;
        data.Descrizione = scale.Descrizione;
        data.PesoNetto = data.PesoNetto == 0 ? data.PesoLordo - data.PesoTara : data.PesoNetto;
        data.PesoLordo = data.PesoLordo == 0 ? data.PesoNetto + data.PesoTara : data.PesoLordo;
    }

    /// <summary>
    ///     Verifica e gestisce lo stato delle connessioni sia per i client TCP che OPC UA.
    ///     Tenta di ristabilire le connessioni per i client disconnessi eseguendo le operazioni in parallelo e indipendente.
    /// </summary>
    /// <returns>
    ///     Un <see cref="Task" /> che rappresenta l'operazione asincrona di verifica e riconnessione.
    ///     Le eventuali eccezioni durante la connessione dei singoli client vengono gestite internamente
    ///     e registrate nella console, senza interrompere il processo complessivo.
    /// </returns>
    private async Task CheckConnection()
    {
        try
        {
            // Crea una lista di task per eseguire le connessioni TCP in parallelo
            var tcpTasks = _balanceClients.Keys.ToList()
                .Select(key => Task.Run(() => ConnectTcpClient(key)))
                .ToList();

            // Crea una lista di task per eseguire le connessioni OPC UA in parallelo
            var opcUaTasks = _opcUaClients.Keys.ToList()
                .Select(key => Task.Run(() => ConnectOpcUaClient(key)))
                .ToList();

            // Combina tutti i task e attendi il completamento
            var allTasks = tcpTasks.Concat(opcUaTasks).ToList();
            await Task.WhenAll(allTasks);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Errore durante il controllo delle connessioni: {ex.Message}");
        }
    }

    /// <summary>
    ///     Stabilisce la connessione con un client TCP della bilancia utilizzando la chiave specificata.
    /// </summary>
    /// <param name="key">
    ///     La chiave univoca che identifica il client TCP della bilancia da connettere.
    /// </param>
    private void ConnectTcpClient(string key)
    {
        try
        {
            if (_balanceClients.TryGetValue(key, out var client))
                client.Connect();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Errore durante la connessione alla bilancia TCP {key}: {ex.Message}");
        }
    }
    
    /// <summary>
    ///     Gestisce la connessione di un client OPC UA al dispositivo specificato.
    /// </summary>
    /// <param name="key">
    ///     La chiave identificativa del dispositivo OPC UA da connettere.
    /// </param>
    /// <returns>
    ///     Un <see cref="Task" /> rappresentante l'operazione asincrona della connessione.
    /// </returns>
    private async Task ConnectOpcUaClient(string key)
    {
        try
        {
            if (_opcUaClients.TryGetValue(key, out var client) && !client.IsConnected)
                await client.Connect();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Errore durante la connessione al dispositivo OPC UA {key}: {ex.Message}");
        }
    }

    /// <summary>
    ///     Mostra i dettagli di una pesata di bilancia ricevuta.
    /// </summary>
    /// <param name="pesata">
    ///     Un oggetto di tipo <see cref="PesataDto" /> contenente le informazioni dettagliate
    ///     della pesata, comprese proprietà quali peso netto, peso lordo, tara, unità di misura
    ///     e altri dati relativi alla bilancia.
    /// </param>
    private static void ShowPesataDto(PesataDto pesata)
    {
        Console.WriteLine(
            $"\n{DateTime.UtcNow:dd/MM/yyyy HH:mm:ss} - Pesata bilancia '{pesata.Codice}' ({pesata.Descrizione}):");
        Console.WriteLine($"StatoBilancia: {pesata.StatoBilancia}");
        Console.WriteLine($"NumeroBilancia: {pesata.NumeroBilancia}");
        Console.WriteLine($"PesoNetto: {pesata.PesoNetto}");
        Console.WriteLine($"PesoTara: {pesata.PesoTara}");
        Console.WriteLine($"PesoLordo: {pesata.PesoLordo}");
        Console.WriteLine($"NumeroPezzi: {pesata.NumeroPezzi}");
        Console.WriteLine($"PesoMedioUnitario: {pesata.PesoMedioUnitario}");
        Console.WriteLine($"UnitaMisura: {pesata.UnitaMisura}");
        Console.WriteLine();
    }
}