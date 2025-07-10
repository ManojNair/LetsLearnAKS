const express = require('express');
const redis = require('redis');
const app = express();
const port = 3000;

// Redis client
const client = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
});

client.on('error', (err) => console.log('Redis Client Error', err));

app.get('/', async (req, res) => {
    try {
        // Increment visit counter
        const visits = await client.incr('visits');
        res.json({
            message: 'Hello from Multi-Service App!',
            visits: visits,
            timestamp: new Date().toISOString(),
            hostname: require('os').hostname()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
    console.log(`App listening at http://localhost:${port}`);
}); 