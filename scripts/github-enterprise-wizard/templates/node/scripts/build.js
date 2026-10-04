import {mkdir, copyFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

const root = new URL('../', import.meta.url);
await mkdir(new URL('dist/', root), {recursive: true});
await copyFile(fileURLToPath(new URL('src/index.js', root)), fileURLToPath(new URL('dist/index.js', root)));
