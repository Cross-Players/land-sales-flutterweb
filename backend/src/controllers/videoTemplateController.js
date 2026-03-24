const videoTemplates = require('../data/videoTemplates');

/**
 * @desc    Get all video templates
 * @route   GET /api/v1/video-templates
 * @access  Public
 */
const getAllTemplates = async (req, res, next) => {
    try {
        const { tag, search, isPopular } = req.query;

        let filteredTemplates = [...videoTemplates];

        // Filter by tag
        if (tag) {
            filteredTemplates = filteredTemplates.filter(
                template => template.tag.toLowerCase() === tag.toLowerCase()
            );
        }

        // Filter by popular
        if (isPopular === 'true') {
            filteredTemplates = filteredTemplates.filter(
                template => template.isPopular === true
            );
        }

        // Search by title or description
        if (search) {
            const searchLower = search.toLowerCase();
            filteredTemplates = filteredTemplates.filter(
                template =>
                    template.title.toLowerCase().includes(searchLower) ||
                    template.description.toLowerCase().includes(searchLower)
            );
        }

        res.json({
            success: true,
            count: filteredTemplates.length,
            data: filteredTemplates
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Get single template by ID
 * @route   GET /api/v1/video-templates/:id
 * @access  Public
 */
const getTemplateById = async (req, res, next) => {
    try {
        const { id } = req.params;

        const template = videoTemplates.find(t => t.id === id);

        if (!template) {
            return res.status(404).json({
                success: false,
                error: 'Template not found',
                message: `Template with id '${id}' does not exist`
            });
        }

        res.json({
            success: true,
            data: template
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Get templates by category/tag
 * @route   GET /api/v1/video-templates/category/:category
 * @access  Public
 */
const getTemplatesByCategory = async (req, res, next) => {
    try {
        const { category } = req.params;

        const filteredTemplates = videoTemplates.filter(
            template => template.tag.toLowerCase() === category.toLowerCase()
        );

        if (filteredTemplates.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'No templates found',
                message: `No templates found for category '${category}'`
            });
        }

        res.json({
            success: true,
            count: filteredTemplates.length,
            category,
            data: filteredTemplates
        });
    } catch (error) {
        next(error);
    }
};

/**
 * @desc    Get popular templates
 * @route   GET /api/v1/video-templates/popular/list
 * @access  Public
 */
const getPopularTemplates = async (req, res, next) => {
    try {
        const popularTemplates = videoTemplates.filter(t => t.isPopular === true);

        res.json({
            success: true,
            count: popularTemplates.length,
            data: popularTemplates
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getAllTemplates,
    getTemplateById,
    getTemplatesByCategory,
    getPopularTemplates
};
