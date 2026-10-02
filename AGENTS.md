# AGENTS.md

Guida per chi lavora su questo repository (persone e agenti). Documento vivo: gli obiettivi cambiano
raramente, il **modus operandi** si arricchisce man mano che prendiamo decisioni. Quando se ne prende una
nuova, va aggiunta qui (e, se architetturale, registrata come ADR in `docs/adr/`).

## 1. Obiettivi di progetto

Showcase locale di **Magnolia CMS** da mostrare al business, pubblico su GitHub. Deve far vedere:

1. le **feature del CMS** (editing in-page, DAM, workflow, ecc.);
2. **Author e Public instance** (una sola public basta) con pubblicazione/replica;
3. lo **sviluppo di un sito di media complessità**;
4. la possibilità di **dockerizzazione / Kubernetes**;
5. come fare **test automation**;
6. l'**estensione di feature standard** (senza modificare il core);
7. l'adozione di un **design system** (da costruire con un agente designer su Figma).

Vincoli: usare lo stato dell'arte di Magnolia **documentato online** e lo stato dell'arte di architettura per
progetti web/CMS. Esecuzione locale su Mac (supporto Windows per l'avvio).

## 2. Decisioni prese

| Tema | Scelta | Note |
|---|---|---|
| Versione | Magnolia **6.4.10** (`magnoliaBundleVersion` nel `pom.xml` padre) | Jakarta EE 10 |
| Edizione | **Community Edition** (GPLv3, nessuna chiave) | 1 author + 1 public. Il passaggio a DX Core avviene importando il suo BOM; la chiave di licenza non va mai nel repo |
| Java | **JDK 21** (certificati 17, 21, 25) | Il JDK 27 non è certificato. Per lo showcase si resta su 21; il percorso verso 25 (flag JVMCI, `javascript-models` ≥ 4.0.1) è nel README |
| Toolchain su Mac | **mise** (`mise.toml`): JDK 21 e task `up/down/reset/build`, `logs[-author\|-public]`, `start-/stop-author\|public`, `db-author\|public` | Su Windows si usano direttamente i comandi `docker compose` |
| Application server | **Tomcat 10.1** | Unico certificato. Tomcat 11 non supportato, Jetty non certificato |
| Rendering | **Server-side**: light module (YAML + FreeMarker) | Variante headless valutabile in seguito |
| Avvio locale | **Docker Compose** | Il build avviene in Docker: non serve Java/Maven sull'host |
| Runtime container | **OrbStack** su Mac (consigliato), Docker Desktop su Windows | OrbStack gestisce immagini, container e volumi; Docker Desktop su Mac resta valido |
| URL locali | `http://author.localhost:8080` e `http://public.localhost:8081`, **mai** `localhost` per entrambe | I cookie non distinguono le porte: con lo stesso host il cookie `csrf` delle due istanze si sovrascrive e il login dà 403. Verificato con `curl`; i dettagli sono nel README |
| Una immagine, due ruoli | `MAGNOLIA_INSTANCE_TYPE=author\|public` | Verificato: seleziona la cartella di bootstrap corretta |
| Persistenza | **PostgreSQL 17**, un database per istanza (`magnolia_author`, `magnolia_public`) | Profilo Magnolia `showcase` (`MAGNOLIA_PROFILE`) e XML Jackrabbit con `DataSource` da proprietà di sistema, valorizzate da `docker/setenv.sh` a partire da `MGNL_DB_*`. Indici e datastore restano su file nei volumi |

## 3. Modus operandi

- **Documentazione ufficiale prima di tutto.** Per ogni scelta su Magnolia si parte da
  <https://docs.magnolia-cms.com>. Dove la doc è muta o ambigua si verifica empiricamente e si annota qui.
  Non si dichiara "supportato da Magnolia" ciò che è una nostra scelta (es. Playwright, Docker).
- **Verificare prima di dichiarare fatto.** Un comando va nel README solo se è stato eseguito.
- **Build riproducibile.** Si costruisce con Docker o con `./mvnw` (Maven Wrapper). Niente Maven installato globalmente.
- **Comandi come task mise.** I comandi ricorrenti vivono in `mise.toml`; quando se ne aggiunge uno si aggiorna
  anche la tabella "Comandi utili" del README, con l'equivalente per Windows.
- **Un solo artefatto** (WAR/immagine) per author e public; la differenza è configurazione a runtime (12-factor).
- **Content as code.** Template, dialog e contenuti demo stanno in git (light module e bootstrap), così la demo si riproduce a ogni clone.
- **Estendere, non modificare.** Le feature standard si estendono con la decorazione delle definizioni, mai toccando il core.
- **Repository pubblico.** Mai segreti, chiavi di licenza o password reali. Solo un `.env.example` con valori demo.
- **Diagrammi nel README** (Mermaid, sezione "Architettura"): mostrano solo ciò che esiste; ciò che è pianificato va
  tratteggiato. Si aggiornano nella stessa PR che cambia l'architettura.
- **Decisioni architetturali** registrate come ADR (MADR) in `docs/adr/`.
- **Struttura**: `webapp/` (WAR), `light-modules/` (sito), `docker-compose.yml` e `Dockerfile` alla radice;
  in arrivo `deploy/helm/`, `e2e/`, `design-system/`.

## 4. Stato

- [x] Scheletro Maven (padre + `webapp`), build del WAR 6.4.10
- [x] Immagine Docker e Compose con author (`:8080`) e public (`:8081`)
- [x] PostgreSQL al posto di H2 (già dalla prima installazione)
- [ ] Subscriber author → public (replica) funzionante nel Compose
- [ ] Light module `showcase-site` e contenuti demo
- [ ] Modulo Java di estensione
- [ ] Helm chart / Kubernetes locale
- [ ] Test end-to-end (Playwright) e CI su GitHub Actions
- [ ] Design system (Figma → token → componenti)
