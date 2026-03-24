# Video Template Backend API

Backend API cho Video Template Management được xây dựng với Node.js + Express.

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ 
- npm hoặc yarn

### Installation

```bash
# Clone repository
cd backend

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Start development server
npm run dev
```

Server sẽ chạy tại `http://localhost:3000`

## 📡 API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

### Video Templates

#### 1. Get All Templates
```http
GET /api/v1/video-templates
```

**Query Parameters:**
- `tag` (string, optional): Filter by tag (e.g., "Hiện đại", "Cao cấp")
- `isPopular` (boolean, optional): Filter popular templates only
- `search` (string, optional): Search by title or description

**Response:**
```json
{
  "success": true,
  "count": 6,
  "data": [
    {
      "id": "property-showcase",
      "title": "Property Showcase",
      "description": "Tạo video giới thiệu bất động sản...",
      "imageUrl": "https://images.unsplash.com/...",
      "tag": "Hiện đại",
      "isPopular": true,
      "category": "real-estate",
      "duration": 60,
      "features": ["...", "..."],
      "createdAt": "2024-01-15T00:00:00.000Z",
      "updatedAt": "2024-03-10T00:00:00.000Z"
    }
  ]
}
```

#### 2. Get Template by ID
```http
GET /api/v1/video-templates/:id
```

**Example:**
```bash
curl http://localhost:3000/api/v1/video-templates/property-showcase
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "property-showcase",
    "title": "Property Showcase",
    ...
  }
}
```

#### 3. Get Templates by Category
```http
GET /api/v1/video-templates/category/:category
```

**Example:**
```bash
curl http://localhost:3000/api/v1/video-templates/category/Hiện%20đại
```

#### 4. Get Popular Templates
```http
GET /api/v1/video-templates/popular/list
```

**Example:**
```bash
curl http://localhost:3000/api/v1/video-templates/popular/list
```

## 🧪 Testing API

### Using cURL

```bash
# Get all templates
curl http://localhost:3000/api/v1/video-templates

# Get popular templates only
curl http://localhost:3000/api/v1/video-templates?isPopular=true

# Get templates by tag
curl http://localhost:3000/api/v1/video-templates?tag=Hiện%20đại

# Search templates
curl http://localhost:3000/api/v1/video-templates?search=penthouse

# Get specific template
curl http://localhost:3000/api/v1/video-templates/luxury-collection
```

### Using Postman/Insomnia

Import the API endpoints or manually create requests to:
- `GET http://localhost:3000/api/v1/video-templates`
- `GET http://localhost:3000/api/v1/video-templates/:id`
- `GET http://localhost:3000/api/v1/video-templates/category/:category`
- `GET http://localhost:3000/api/v1/video-templates/popular/list`

## 🏗️ Project Structure

```
backend/
├── src/
│   ├── controllers/
│   │   └── videoTemplateController.js    # Business logic
│   ├── data/
│   │   └── videoTemplates.js             # Template data
│   ├── routes/
│   │   ├── index.js                      # Main router
│   │   └── videoTemplates.js             # Template routes
│   └── server.js                         # Express app setup
├── .env                                  # Environment variables
├── .gitignore
├── package.json
└── README.md
```

## 🔧 Available Scripts

```bash
# Start production server
npm start

# Start development server with auto-reload
npm run dev

# Run tests
npm test
```

## 🌍 Environment Variables

```env
PORT=3000
NODE_ENV=development
API_VERSION=v1
CORS_ORIGIN=http://localhost:*
```

## 📦 Dependencies

- **express** - Web framework
- **cors** - Enable CORS
- **helmet** - Security headers
- **morgan** - HTTP request logger
- **compression** - Response compression
- **dotenv** - Environment variables

## 🚢 Deployment

### Deploy to Railway

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Deploy
railway up
```

### Deploy to Heroku

```bash
# Login
heroku login

# Create app
heroku create your-app-name

# Push to Heroku
git push heroku main
```

### Deploy to DigitalOcean/AWS

1. Create a Droplet/EC2 instance
2. SSH into server
3. Clone repository
4. Install dependencies: `npm install`
5. Start with PM2: `pm2 start src/server.js`

## 📝 Future Enhancements

- [ ] Add PostgreSQL database
- [ ] Implement authentication (JWT)
- [ ] Add POST/PUT/DELETE endpoints
- [ ] File upload for custom templates
- [ ] Rate limiting
- [ ] Caching with Redis
- [ ] API documentation with Swagger
- [ ] Unit tests with Jest
- [ ] Integration with AI services

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 💬 Support

For support, email your-email@example.com or open an issue in the repository.
