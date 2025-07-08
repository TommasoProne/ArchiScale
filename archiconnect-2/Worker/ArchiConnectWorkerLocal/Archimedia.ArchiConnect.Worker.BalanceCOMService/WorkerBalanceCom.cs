using Archimedia.ArchiConnect.Worker.Balance.Interfaces;
using Archimedia.ArchiConnect.Worker.Balance.Models;
using Archimedia.ArchiConnect.Worker.Balance.Services;
using Archimedia.ArchiConnect.Worker.Service.Interfaces;
using Archimedia.ArchiConnect.Worker.Shared.Helpers;
using Archimedia.ArchiConnect.Worker.Shared.Models;
using Microsoft.Extensions.Options;
using System;
using System.IO.Ports;

namespace Archimedia.ArchiConnect.Worker.BalanceCOMService;

public class WorkerBalanceCom(
    IBalanceClientService balanceClientService,
    IOrdiniService ordiniService,
    IRisorseService risorseService,
    IOptions<WorkerSettings> settings) : BackgroundService
{
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
                var indicatore = await ordiniService.GetRisorsa(
                    _settings.OrganizzazioneId,
                    _settings.RisorsaId);

                if (indicatore.TipoRisorsa == 3)
                {
                    //check formato
                    
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