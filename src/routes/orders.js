const express = require('express');
const router  = express.Router();

// GET /api/orders
router.get('/', (req, res) => {
  res.json({ orders: [], message: 'FoodExpress Orders API' });
});

// POST /api/orders
router.post('/', (req, res) => {
  const { items, address } = req.body;
  if (!items || !address) {
    return res.status(400).json({ error: 'items and address are required' });
  }
  res.status(201).json({ orderId: Date.now(), status: 'received', items, address });
});

module.exports = router;
