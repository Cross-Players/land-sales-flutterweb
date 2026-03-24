const express = require('express');
const router = express.Router();
const videoTemplateController = require('../controllers/videoTemplateController');

/**
 * @route   GET /api/v1/video-templates
 * @desc    Get all video templates
 * @access  Public
 */
router.get('/', videoTemplateController.getAllTemplates);

/**
 * @route   GET /api/v1/video-templates/:id
 * @desc    Get single video template by ID
 * @access  Public
 */
router.get('/:id', videoTemplateController.getTemplateById);

/**
 * @route   GET /api/v1/video-templates/category/:category
 * @desc    Get templates by category
 * @access  Public
 */
router.get('/category/:category', videoTemplateController.getTemplatesByCategory);

/**
 * @route   GET /api/v1/video-templates/popular/list
 * @desc    Get popular templates only
 * @access  Public
 */
router.get('/popular/list', videoTemplateController.getPopularTemplates);

module.exports = router;
