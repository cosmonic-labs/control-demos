# Cosmonic Control Welcome Tour

This Wasm component introduces users to the core features of Cosmonic Control. It is built on [Hono](https://hono.dev) and based on the [HTTP Server with Hono wasmCloud example](https://github.com/wasmCloud/typescript/tree/main/examples/components/http-server-with-hono).

The component serves a simple web app that embeds assets like fonts and images directly in the HTML.

It also uses `wasi:config/runtime` to pass config from the environment to the Hono app for values such as the Console UI address.

## Dependencies

- `wash` - [wasmCloud Shell][wash] controls your [wasmCloud][wasmcloud] host instances and enables building components
- `npm` - [Node Package Manager (NPM)][npm] which manages packages for for the NodeJS ecosystem
- `node` - [NodeJS runtime][nodejs] (see `.nvmrc` for version)

[wash]: https://github.com/cosmonic-labs/wash
[node]: https://nodejs.org
[npm]: https://github.com/npm/cli

## Quickstart

1. Install dependencies and start a development loop

   ```shell
   wash dev --runtime-config consoleurl=127.0.0.1:8000
   ```

   or

   ```shell
   npm run start
   ```

   Navigate to [127.0.0.1:8000](127.0.0.1:8000).
