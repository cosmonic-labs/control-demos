import {Hono, Context} from 'hono';
import { swaggerUI } from '@hono/swagger-ui'

import {serve, type WasiEnv} from './wasmcloud/hono-adapter';
import {wasiLog} from './wasmcloud/hono-middleware-wasi-logging';

// Initialize Hono app
const app = new Hono<WasiEnv>();

// A basic OpenAPI document
const openApiDoc = {
  openapi: "3.0.0", // This is the required version field
  info: {
    title: "API Documentation",
    version: "1.0.0",
    description: "API documentation for your service",
  },
  paths: {
    // Add your API paths here
    "/health": {
      get: {
        summary: "Health check",
        responses: {
          "200": {
            description: "OK",
          },
        },
      },
    },
    // Add more endpoints as needed
  },
};

// Middleware for logging
app.use(wasiLog());

// Serve the OpenAPI document
app.get("/doc", (c: Context) => c.json(openApiDoc));

// Use the middleware to serve Swagger UI at /ui
app.get('/ui', swaggerUI({ url: '/doc' }))

app.get("/health", (c: Context) => c.text("OK"));

// handle missing routes
app.notFound((c: Context) => {
  const example = c.env.example;
  return c.json({error: '404 Not Found'}, 404);
});

serve(app);
