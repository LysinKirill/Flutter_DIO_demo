# Dio File Uploader

Этот проект демонстрирует использование библиотеки **Dio** во Flutter для обработки REST API запросов, загрузки файлов, обработки ошибок, кэширования и многого другого. Ниже приведено описание ключевых функций, используемых в этом проекте.

---

## Демонстрируемые функции

### 1. **Загрузка файлов**
Dio поддерживает загрузку файлов с использованием `MultipartFile`. Это полезно для загрузки изображений, документов или других файлов на сервер.

#### Пример кода:
```dart
FormData formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(_filePath!),
});

Response response = await dio.post(
  uploadUrl,
  data: formData,
  onSendProgress: (int sent, int total) {
    setState(() {
      _uploadProgress = sent / total;
    });
  },
);
```
2. Отслеживание прогресса
Dio предоставляет callback (onSendProgress) для отслеживания прогресса загрузки или скачивания файлов.

Пример кода:
```dart
onSendProgress: (int sent, int total) {
  setState(() {
    _uploadProgress = sent / total;
  });
},
```
3. Обработка ошибок
Dio имеет встроенную обработку ошибок с использованием класса DioError. Это позволяет обрабатывать различные типы ошибок, такие как тайм-ауты соединения, сетевые ошибки и ошибки сервера.

Пример кода:
```dart
try {
  Response response = await dio.post(uploadUrl, data: formData);
} on DioError catch (e) {
  if (e.type == DioErrorType.connectTimeout) {
    setState(() {
      _errorMessage = 'Ошибка загрузки: Тайм-аут соединения';
    });
  } else if (e.type == DioErrorType.other) {
    setState(() {
      _errorMessage = 'Ошибка загрузки: Нет интернет-соединения';
    });
  } else {
    setState(() {
      _errorMessage = 'Ошибка загрузки: ${e.message}';
    });
  }
}
```

4. Отмена запросов
Dio поддерживает отмену запросов с использованием CancelToken. Это полезно для отмены текущих запросов, например, загрузки файлов, когда пользователь уходит со страницы или вручную отменяет операцию.

Пример кода:
```dart
CancelToken _cancelToken = CancelToken();

// Начало загрузки с токеном отмены
Response response = await dio.post(
  uploadUrl,
  data: formData,
  cancelToken: _cancelToken,
);

// Отмена запроса
_cancelToken.cancel('Загрузка отменена пользователем');

// Сброс токена для будущих запросов
void _resetCancelToken() {
  _cancelToken = CancelToken();
}
```
5. Кэширование
Dio может быть расширен с помощью пакета dio_http_cache для поддержки кэширования ответов. Это уменьшает количество избыточных сетевых запросов, предоставляя кэшированные ответы.

Пример кода:
```dart
import 'package:dio_http_cache/dio_http_cache.dart';

// Добавление интерцептора для кэширования
dio.interceptors.add(DioCacheManager(CacheConfig(baseUrl: 'https://jsonplaceholder.typicode.com')).interceptor);

// Получение данных с кэшированием
Response response = await dio.get(
  'https://jsonplaceholder.typicode.com/posts/1',
  options: buildCacheOptions(Duration(minutes: 1)), // Кэширование на 1 минуту
);
```

6. Логирование запросов и ответов
Dio предоставляет LogInterceptor для логирования запросов и ответов, что полезно для отладки.

Пример кода:
```dart
dio.interceptors.add(LogInterceptor(
  request: true,
  requestHeader: true,
  requestBody: true,
  responseHeader: true,
  responseBody: true,
  error: true,
));
```
---

### Реализованные фичи:
- Загрузка файлов: Приложение позволяет пользователю выбрать файл и загрузить его на сервер.

- Отслеживание прогресса: Прогресс загрузки отображается с помощью LinearProgressIndicator.

- Обработка ошибок: Ошибки во время загрузки отображаются пользователю.

- Отмена запросов: Пользователь может отменить текущую загрузку.

- Кэширование: Приложение демонстрирует, как кэшировать ответы API с помощью dio_http_cache.

- Логирование: Все запросы и ответы логируются для отладки.

---

### Скриншоты
#### Экран загрузки файлов
![Main Screen](/screenshots/main_page.png)
#### Загрузка
![Upload](/screenshots/upload.png)

#### Ошибка загрузки
![Upload Failed](/screenshots/upload_failed.png)
---

## Заключение

---

Этот проект демонстрирует мощь и гибкость библиотеки Dio для обработки REST API запросов во Flutter. С такими функциями, как загрузка файлов, отслеживание прогресса, обработка ошибок, отмена запросов и кэширование, Dio является надежным выбором для современных приложений на Flutter.

Для получения дополнительной информации ознакомьтесь с документацией Dio.
