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
│   ├── metodo.mdx            # ensayo
│   ├── app-garmin.astro      # showcase
│   └── analizador.astro      # herramienta
├── components/analyzer/      # islas React
├── lib/                      # parser TCX/GPX, storage, share, cálculos protocolo
└── styles/global.css
```

## Créditos

- Mariano García-Verdugo — DIPER original.
- Roberto Álvarez — modificación progresiva continua.
- Analizador TCX/GPX portado y adaptado desde el proyecto [`gatos`](https://github.com/marioperezpereira/gatos) (privado).
