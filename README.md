# 🎮 Sandbox ATB

Un progetto sperimentale sviluppato in [Godot Engine](https://godotengine.org/) per testare e prototipare un sistema di combattimento a turni in stile **ATB (Active Time Battle)**, ispirato ai classici giochi di ruolo giapponesi.

## 🧠 Obiettivo

Il progetto nasce come sandbox per sperimentare meccaniche di combattimento, gestione delle unità, turni, abilità e interfacce grafiche in un contesto da JRPG. È pensato come base modulare per giochi a turni o per evolvere verso prototipi più complessi.

## 🚀 Caratteristiche principali

- ⚔️ Sistema di unità **Party/Enemy** con script dedicati (`PartyUnit.gd`, `EnemyUnit.gd`)
- 🔄 Meccanica **ATB** in sviluppo, con gestione dei turni e barre di attesa
- ✨ Supporto per abilità personalizzate
- 🧩 Sistema modulare facilmente estendibile
- 🎨 Interfaccia utente in costruzione (`UI/`), pensata per chiarezza e accessibilità
- 🌍 Scene per livelli e test di gameplay (`Levels/`)

## 🗂 Struttura del progetto

```
.
├── Characters/       # Scene e script relativi alle unità
├── Levels/           # Scene per il testing e livelli di esempio
├── Skills/           # Script e dati delle abilità
├── UI/               # Componenti dell'interfaccia utente
├── GlobalScript.gd   # Script globale con costanti o metodi condivisi
├── project.godot     # File di configurazione del progetto Godot
```

## 🛠 Requisiti

- [Godot Engine 4.x](https://godotengine.org/download)

## 📦 Come avviare il progetto

1. Clona la repository:
   ```bash
   git clone https://github.com/elgabroGit/sandbox-atb.git
   ```
2. Apri la cartella dal launcher di Godot
3. Avvia la scena principale per iniziare i test (scegli una scena da `Levels/`)

## 🧪 Stato del progetto

> ⚠️ Il progetto è in fase prototipale. Molte funzionalità sono work-in-progress o ancora da implementare.

## 📄 Licenza

Questo progetto è distribuito sotto la licenza MIT. Vedi il file `LICENSE` per maggiori dettagli.

---

👾 Creato con passione da [@elgabroGit](https://github.com/elgabroGit)
