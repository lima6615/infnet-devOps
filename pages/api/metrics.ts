import type { NextApiRequest, NextApiResponse } from 'next';
import client from 'prom-client';

const registry = new client.Registry();

client.collectDefaultMetrics({ register: registry });

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  res.setHeader('Content-Type', registry.contentType);
  res.end(await registry.metrics());
}