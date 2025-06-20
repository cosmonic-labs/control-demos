# Cosmonic Control Welcome Tour

This Wasm component introduces users to the core features of Cosmonic Control. It is built on [Hono](https://hono.dev) and based on the [HTTP Server with Hono wasmCloud example](https://github.com/wasmCloud/typescript/tree/main/examples/components/http-server-with-hono). 

The component serves a simple web app that embeds assets like fonts and images directly in the HTML. 

It also uses `wasi:config/runtime` to pass config from the environment to the Hono app for values such as the Console UI address.

## Dependencies

* `wash` - [wasmCloud Shell][wash] controls your [wasmCloud][wasmcloud] host instances and enables building components
* `npm`  - [Node Package Manager (NPM)][npm] which manages packages for for the NodeJS ecosystem
* `node` - [NodeJS runtime][nodejs] (see `.nvmrc` for version)

[wash]: https://github.com/wasmCloud/wasmCloud/tree/main/crates/wash-cli
[node]: https://nodejs.org
[npm]: https://github.com/npm/cli

## Quickstart

1. Install dependencies:

   ```bash
   npm install
   ```

2. Build the project:

   ```bash
   wash build
   ```

3. Run with `wash` (development)

   ```shell
   wash up -d
   ```
   ```shell
   wash app deploy dev.yaml
   ```

   Navigate to [localhost:9000](localhost:9000).

   **Note**: If you use `wash dev` to run the component locally, you will not see the config value for the Console UI address. This is due to a [known bug](https://github.com/wasmCloud/wasmCloud/issues/4522). 


