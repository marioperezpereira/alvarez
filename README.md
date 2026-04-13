# DIPER · Álvarez

Sitio web del test progresivo DIPER en su modificación por Roberto Álvarez sobre el protocolo original de Mariano García-Verdugo.

Incluye:

- **Protocolo** — explicación científica y accesible.
- **App Garmin** — showcase de `Alvarez — Diper` (Connect IQ).
- **Analizador** — herramienta 100 % client-side para subir TCX/GPX, visualizar vueltas y comparar tests.

## Stack

- Astro 6 + TypeScript
- React islands (Recharts) para el analizador
- Tailwind CSS v4
- MDX para el ensayo del método
- Fuentes self-hosted (Fraunces + Inter)

## Desarrollo

```sh
npm install
npm run dev        # http://localhost:4321/alvarez/
npm run build
npm run preview
```

## Despliegue

GitHub Pages vía Action en `.github/workflows/deploy.yml`. Push a `main` dispara el build y publica en `https://marioperezpereira.github.io/alvarez/`.

## Estructura

```
src/
├── layouts/Base.astro
├── pages/
│   ├── index.astro           # home
│   ├── metodo.mdx            # ensayo científico
│   ├── test.astro            # instrucciones paso a paso + app
│   ├── app-garmin.astro      # 301 → /test#app
│   └── analizador.astro      # herramienta
├── components/analyzer/      # islas React
├── lib/                      # parser TCX/GPX, storage, share, cálculos protocolo
└── styles/global.css

garmin-app/                   # código fuente Monkey C de la app Garmin
├── manifest.xml              # 92 dispositivos compatibles
├── source/                   # WorkoutSession, ActivityView, etc.
└── resources/                # icono y strings
```

### App Garmin (`garmin-app/`)

App Connect IQ que ejecuta el protocolo en el reloj. Para compilarla necesitas el SDK de Connect IQ
(`monkeyc`) y tu propia `developer_key`. Build de release:

```sh
cd garmin-app
monkeyc -e -o bin/Alvarez.iq -f monkey.jungle -y /path/to/developer_key.der
```

Publicada en Connect IQ Store: <https://apps.garmin.com/en-US/apps/2cf041b6-28ad-4d4d-ba77-31f2a947d2b1>

## Créditos

- Mariano García-Verdugo — DIPER original.
- Roberto Álvarez — modificación progresiva continua.
- Analizador TCX/GPX portado y adaptado desde el proyecto [`gatos`](https://github.com/marioperezpereira/gatos) (privado).
