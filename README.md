# Magnolia Showcase

Progetto dimostrativo per mostrare le potenzialità di [Magnolia CMS](https://www.magnolia-cms.com) (versione 6.4, Community Edition):
istanze **Author** e **Public**, un sito di media complessità sviluppato come *content as code*, esecuzione in
container (Docker, poi Kubernetes), test automatici, estensione di feature standard e un design system.

Gli obiettivi, le decisioni e il modo di lavorare sono in [AGENTS.md](AGENTS.md).

## Requisiti

Il build usa JDK 21 e Maven **dentro il container**: per avviare il progetto serve solo **Docker** con Docker Compose v2.

- **macOS:** consigliato [OrbStack](https://orbstack.dev), un'alternativa leggera a Docker Desktop che
  include `docker` e `docker compose` (`brew install --cask orbstack`). Da OrbStack si vedono anche
  container, immagini e volumi del progetto e se ne aprono i log. Anche Docker Desktop funziona.
  Per toolchain e comandi si usa [mise](https://mise.jdx.dev) (`brew install mise`).
- **Windows:** Docker Desktop.

## Avvio in locale

Dalla radice del repository.

**macOS** (Terminale, con mise)

```bash
mise install      # una tantum: installa il JDK 21 definito in mise.toml
mise run up       # build + avvio di author e public
```

**Windows** (PowerShell, con Docker Desktop attivo)

```powershell
docker compose up -d --build
```

Su Mac `mise run up` esegue lo stesso `docker compose up -d --build`, quindi funziona anche senza mise.
La prima volta il build scarica circa 200 MB di dipendenze e richiede alcuni minuti. Gli avvii successivi
sono rapidi (circa 20 secondi). Provato su Mac con OrbStack; su Windows non ancora.

| Istanza | URL |
|---|---|
| Author | <http://localhost:8080/.magnolia/admincentral> |
| Public | <http://localhost:8081> |

**Primo accesso.** Magnolia 6.4 mostra una pagina in cui impostare la password dell'utente `superuser`.
Va fatto una volta per istanza (author e public hanno dati separati).

### Comandi utili

| Cosa | macOS (mise) | Windows / senza mise |
|---|---|---|
| Avvia | `mise run up` | `docker compose up -d --build` |
| Segui i log | `mise run logs` | `docker compose logs -f` |
| Ferma e rimuove i container (i dati restano) | `mise run down` | `docker compose down` |
| Riparte da zero (cancella anche i dati) | `mise run reset` | `docker compose down -v` |
| Build locale del WAR, senza Docker | `mise run build` | `.\mvnw.cmd -B -DskipTests package` |

`mise tasks` elenca tutti i task. Il WAR del build locale è `webapp/target/showcase.war`.

## Ciclo di sviluppo

Il runtime resta in Docker: l'IDE serve solo per scrivere i file e non devi far girare Tomcat dall'IDE.

| Cosa modifichi | Dove | Cosa succede |
|---|---|---|
| Template FreeMarker, dialog, CSS/JS, YAML | `light-modules/<modulo>/…` | La cartella è montata nel container e Magnolia la legge da `magnolia.resources.dir`. Secondo la [documentazione](https://docs.magnolia-cms.com/product-docs/6.2/developing/light-development-in-magnolia/) le modifiche sono rilevate senza riavvio: salvi e aggiorni il browser |
| Codice Java (moduli di estensione) | `modules/…` (in arrivo) | Va ricostruita l'immagine con `mise run up`: più lento, qualche minuto |
| Contenuti | Author (`:8080`) | Si modificano nell'editor visuale e si pubblicano sulla public. I contenuti demo verranno esportati in git come bootstrap |

Flusso tipico: scrivi nell'IDE, salvi, guardi la pagina sull'Author, la pubblichi, controlli la Public (`:8081`).

**Stato della verifica.** È verificato che la cartella `light-modules/` arrivi dentro il container. Il reload a caldo
vero e proprio non è ancora stato provato: lo verificheremo col primo light module del sito. Per lo sviluppo la
documentazione indica anche la proprietà `magnolia.develop=true`, che disattiva la cache delle risorse: non è ancora
impostata nel `docker-compose.yml`. Il debug del codice Java nel container richiederà una porta JDWP, anch'essa da aggiungere.

### Configurare l'IDE

In tutti gli IDE si apre la **cartella radice** del repository e si usa il JDK 21 di mise. Il percorso del JDK si
trova con `mise where java`.

#### IntelliJ IDEA

1. *File → Open* sulla radice: importa il progetto Maven dal `pom.xml`.
2. *Project Structure → SDK*: scegli il JDK 21 di mise, oppure aggiungilo indicando il percorso sopra.
3. Installa il plugin [YAML Assistant for IntelliJ](https://www.magnolia-cms.com/marketplace/detail/yaml-assistant-for-intellij.html)
   dal marketplace di Magnolia: autocompletamento dei parametri delle definizioni e riferimenti ai file cliccabili.

#### Visual Studio Code

1. *File → Open Folder* sulla radice.
2. Estensioni consigliate: *Extension Pack for Java* (imposta `java.configuration.runtimes` sul JDK di mise) e *YAML* di Red Hat.
3. Per l'autocompletamento YAML di Magnolia esistono gli schemi della community in
   [magnolia-community/definition-schemas](https://github.com/magnolia-community/definition-schemas), indicati per VS Code ed Eclipse.
   La mappatura dei file sugli schemi non è ancora verificata e non è inclusa nel progetto.

#### Eclipse

1. Usa la distribuzione *Eclipse IDE for Enterprise Java and Web Developers*.
2. *File → Import → Existing Maven Projects* sulla radice.
3. *Preferences → Java → Installed JREs*: aggiungi il JDK 21 di mise.
4. Per YAML e FreeMarker servono plugin dedicati (gli schemi della community indicano Eclipse tra gli IDE supportati).

Il supporto a FreeMarker negli IDE non è stato verificato.

## Versione di Java

Il progetto usa **Java 21**, definito in [mise.toml](mise.toml) (build locale) e nel `Dockerfile`
(`maven:3.9-eclipse-temurin-21` e `tomcat:10.1-jre21-temurin`). Magnolia 6.4 è certificato anche su Java 17 e
**Java 25 (LTS)**; il JDK 27 non è supportato.

Per passare a Java 25 (non ancora provato in questo progetto), secondo il
[certified stack](https://docs.magnolia-cms.com/product-docs/administration/certified-stack/):

- servono `javascript-models` 4.0.1 o superiore: il bundle 6.4.10 include già la 4.0.4;
- aggiungere ai `CATALINA_OPTS` i flag `-XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI`. Senza, GraalJS gira in
  modalità interpretata e nei log compare l'avviso *JVMCI isn't enabled*: il sistema funziona, ma le prestazioni
  peggiorano;
- cambiare `java = "temurin-25"` in `mise.toml`, le immagini nel `Dockerfile` (`eclipse-temurin-25`, `jre25`) e
  `maven.compiler.release` nel `pom.xml` padre; allargare di conseguenza il range del controllo `requireJavaVersion`
  (ora `[17,26)`, già compatibile con il 25).

## Struttura

```text
pom.xml              padre Maven (importa il BOM di Magnolia)
webapp/              WAR basato sulla webapp Community Edition
light-modules/       moduli "light" del sito (YAML, FreeMarker)
Dockerfile           build multi-stage: Maven/JDK 21 → Tomcat 10.1
docker-compose.yml   author + public
mise.toml            JDK 21 e task (up, down, logs, reset, build)
```
