/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_ANASITE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
