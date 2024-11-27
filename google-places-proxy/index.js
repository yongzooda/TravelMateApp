const express = require("express");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(cors());

const API_KEY = 'AIzaSyCR_YT9dN3ei0ZBsiui-9UX8Vj6POVYEHQ';

// Google Places API 프록시 엔드포인트
app.get("/places", async (req, res) => {
    const { latitude, longitude, type } = req.query;
    const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${latitude},${longitude}&radius=5000&type=${type}&key=${API_KEY}`;

    try {
        const response = await axios.get(url);
        res.json(response.data); // 클라이언트에 JSON 데이터 반환
    } catch (error) {
        console.error("Error fetching places:", error.message);
        res.status(500).send("Error fetching places");
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
