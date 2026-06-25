const express = require('express');
const prisma = require('../lib/dualPrisma');
const { sendResponse } = require('../utils/response');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/v1/profile
router.get('/', authenticate, async (req, res) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: req.user.id },
      select: {
        id: true, name: true, email: true, role: true, phone: true,
        class_level: true, class_name: true, school_name: true,
        school_id: true, signup_source: true, otp_verified: true,
        created_at: true, updated_at: true,
      },
    });

    if (!user) return sendResponse(res, 404, false, 'Profile not found.');
    sendResponse(res, 200, true, 'Profile fetched.', user);
  } catch (error) {
    console.error('Profile fetch error:', error);
    sendResponse(res, 500, false, 'Failed to fetch profile.');
  }
});

// PUT /api/v1/profile
router.put('/', authenticate, async (req, res) => {
  try {
    const { name, phone, class_level, class_name, school_name } = req.body;
    const updateData = { updated_at: new Date() };
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (class_level) updateData.class_level = class_level;
    if (class_name) updateData.class_name = class_name;
    if (school_name) updateData.school_name = school_name;

    const user = await prisma.users.update({
      where: { id: req.user.id },
      data: updateData,
      select: { id: true, name: true, email: true, role: true, phone: true, class_level: true, class_name: true, school_name: true, updated_at: true },
    });

    sendResponse(res, 200, true, 'Profile updated.', user);
  } catch (error) {
    sendResponse(res, 500, false, 'Failed to update profile.');
  }
});

module.exports = router;
