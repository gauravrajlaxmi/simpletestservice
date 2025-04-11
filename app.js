const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.json({
        timestamp: new Date().toISOString(),
        ip: req.ip
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
