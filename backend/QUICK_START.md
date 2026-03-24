# Quick Start Guide

## 📋 Bước 1: Cài đặt Dependencies

```bash
cd backend
npm install
```

## 🚀 Bước 2: Chạy Server

```bash
# Development mode (auto-reload)
npm run dev

# hoặc Production mode
npm start
```

Bạn sẽ thấy:
```
🚀 Server is running!

📍 Local:            http://localhost:3000
🏥 Health Check:     http://localhost:3000/health
📡 API Endpoint:     http://localhost:3000/api/v1
🌍 Environment:      development
```

## 🧪 Bước 3: Test API

### Option 1: Sử dụng Browser
Mở browser và truy cập:
```
http://localhost:3000/api/v1/video-templates
```

### Option 2: Sử dụng cURL
```bash
# Get all templates
curl http://localhost:3000/api/v1/video-templates

# Get popular only
curl http://localhost:3000/api/v1/video-templates?isPopular=true

# Get by ID
curl http://localhost:3000/api/v1/video-templates/property-showcase
```

### Option 3: Sử dụng Postman
1. Mở Postman
2. Tạo request mới: `GET http://localhost:3000/api/v1/video-templates`
3. Click Send

## 🔗 Tích hợp với Flutter App

Cập nhật file `api_constants.dart`:

```dart
class ApiConstants {
  // Base URL - Update này
  static const String baseUrl = 'http://localhost:3000'; // hoặc URL deploy của bạn
  
  // Video Templates endpoint
  static const String videoTemplates = '$baseUrl/api/v1/video-templates';
  
  // Existing endpoints
  static const String facebookAutoPost = '$baseUrl/api/v1/facebook/post';
}
```

Sau đó trong Flutter, gọi API:

```dart
// Get all templates
final response = await _dio.get(ApiConstants.videoTemplates);
final templates = response.data['data'] as List;

// Get popular templates
final response = await _dio.get(
  ApiConstants.videoTemplates,
  queryParameters: {'isPopular': 'true'}
);

// Get by ID
final response = await _dio.get(
  '${ApiConstants.videoTemplates}/property-showcase'
);
```

## 🐛 Troubleshooting

### Port already in use
```bash
# Tìm process đang dùng port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Hoặc đổi port trong .env
PORT=3001
```

### CORS Error
Kiểm tra file `.env`:
```env
CORS_ORIGIN=http://localhost:*
```

### Module not found
```bash
# Xóa node_modules và cài lại
rm -rf node_modules package-lock.json
npm install
```

## 📊 Response Format

Tất cả API responses theo format:

**Success:**
```json
{
  "success": true,
  "count": 6,
  "data": [...]
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error name",
  "message": "Error description"
}
```

## 🔥 Hot Tips

1. **Auto-reload**: Dùng `npm run dev` để server tự động restart khi code thay đổi
2. **Logging**: Mọi request được log ra console với `morgan`
3. **Health Check**: Truy cập `/health` để check server status
4. **API Docs**: Xem `README.md` cho full API documentation

## 📞 Support

Nếu gặp vấn đề, check:
1. Node.js version >= 18
2. npm/yarn đã cài đặt
3. Port 3000 không bị conflicts
4. Tất cả dependencies đã được cài đặt
