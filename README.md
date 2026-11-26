# Sleeper Store (GitHub-repo)

Eén repo voor al je Sleeper-apps. De launcher leest `index.json` en toont alles in de Sleeper Store.

```
index.json                       wordt automatisch gemaakt (.github/workflows/index.yml)
apps/<app-id>/<app-id>-<versie>.sleeperapp
tools/sleeper-pack               gereedschap om de index te maken
```

Een app toevoegen of bijwerken: pak hem in met `sleeper-pack pack`, zet het bestand in `apps/<app-id>/`, commit en push. De index wordt vanzelf bijgewerkt.

Zet **nooit** je `CODES.txt` of launcher-code in deze repo. In de pakketten zelf staat de code niet, alleen een bewijs dat zonder de code niet te maken is.

## Sleeper installeren vanuit deze repo

Maak onder **Releases** een release en zet daar `sleeper-launcher-v<versie>.zip` in. Daarna werkt op elke server:

```
curl -fsSL https://raw.githubusercontent.com/EIGENAAR/REPO/main/get-sleeper.sh | sudo bash -s -- EIGENAAR/REPO
```

Zie `UITLEG.md` bij de download voor alle stappen.
