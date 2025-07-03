import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

// Base class for all drawable objects
abstract class DrawableObject {
  // Position of the object (set by the layout manager)
  ui.Offset position = ui.Offset.zero;

  // Size of the object (determined by the object itself)
  ui.Size size = ui.Size.zero;

  // Method to calculate the size of the object based on constraints
  ui.Size calculateSize(ui.Size minSize, ui.Size maxSize);

  // Method to draw the object on the canvas
  void draw(ui.Canvas canvas);

  // Method to handle pointer events
  bool handlePointerEvent(ui.Offset localPosition, ui.PointerData event) {
    return false; // Default implementation does nothing
  }
}

// Vertical layout manager
class VerticalLayoutManager {
  final List<DrawableObject> objects = [];
  ui.Size minSize = ui.Size.zero;
  ui.Size maxSize = ui.Size.zero;
  double spacing = 10.0; // Space between objects

  // Add an object to the layout
  void addObject(DrawableObject object) {
    objects.add(object);
    layout(); // Recalculate layout when an object is added
  }

  // Remove an object from the layout
  void removeObject(DrawableObject object) {
    objects.remove(object);
    layout(); // Recalculate layout when an object is removed
  }

  // Calculate the layout of all objects
  void layout() {
    double y = 0;

    for (var object in objects) {
      // Calculate the size of the object based on constraints
      object.size = object.calculateSize(minSize, maxSize);

      // Position the object with left edge aligned
      object.position = ui.Offset(0, y);

      // Update y for the next object
      y += object.size.height + spacing;
    }
  }

  // Draw all objects
  void draw(ui.Canvas canvas) {
    for (var object in objects) {
      // Save the canvas state
      canvas.save();

      // Translate to the object's position
      canvas.translate(object.position.dx, object.position.dy);

      // Draw the object
      object.draw(canvas);

      // Restore the canvas state
      canvas.restore();
    }
  }

  // Handle pointer events
  bool handlePointerEvent(ui.PointerData event) {
    // Convert global position to local position
    final position = ui.Offset(event.physicalX, event.physicalY);

    // Check each object in reverse order (top-most first)
    for (int i = objects.length - 1; i >= 0; i--) {
      final object = objects[i];
      final objectRect = ui.Rect.fromLTWH(
        object.position.dx, 
        object.position.dy, 
        object.size.width, 
        object.size.height
      );

      // Check if the event is within the object's bounds
      if (objectRect.contains(position)) {
        // Convert global position to object's local position
        final localPosition = position - object.position;

        // Let the object handle the event
        if (object.handlePointerEvent(localPosition, event)) {
          return true; // Event was handled
        }
      }
    }

    return false; // Event was not handled
  }
}

// Rectangle object
class RectangleObject extends DrawableObject {
  ui.Color color;
  double width;
  double height;
  bool isInteractive;

  RectangleObject({
    required this.color,
    required this.width,
    required this.height,
    this.isInteractive = false,
  });

  @override
  ui.Size calculateSize(ui.Size minSize, ui.Size maxSize) {
    // Ensure the size is within constraints
    return ui.Size(
      math.min(math.max(width, minSize.width), maxSize.width),
      math.min(math.max(height, minSize.height), maxSize.height),
    );
  }

  @override
  void draw(ui.Canvas canvas) {
    final paint = ui.Paint()..color = color;
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool handlePointerEvent(ui.Offset localPosition, ui.PointerData event) {
    if (!isInteractive) return false;

    // Handle pointer down event
    if (event.change == ui.PointerChange.down) {
      // Change color on tap
      color = ui.Color((math.Random().nextDouble() * 0xFFFFFF).toInt() | 0xFF000000);
      return true;
    }

    return false;
  }
}

// Circle object
class CircleObject extends DrawableObject {
  ui.Color color;
  double radius;
  bool isInteractive;

  CircleObject({
    required this.color,
    required this.radius,
    this.isInteractive = false,
  });

  @override
  ui.Size calculateSize(ui.Size minSize, ui.Size maxSize) {
    final diameter = radius * 2;
    return ui.Size(
      math.min(math.max(diameter, minSize.width), maxSize.width),
      math.min(math.max(diameter, minSize.height), maxSize.height),
    );
  }

  @override
  void draw(ui.Canvas canvas) {
    final paint = ui.Paint()..color = color;
    canvas.drawCircle(ui.Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool handlePointerEvent(ui.Offset localPosition, ui.PointerData event) {
    if (!isInteractive) return false;

    // Handle pointer down event
    if (event.change == ui.PointerChange.down) {
      // Check if the tap is within the circle
      final center = ui.Offset(size.width / 2, size.height / 2);
      final distance = (localPosition - center).distance;

      if (distance <= radius) {
        // Change radius on tap
        radius = math.max(10, radius + (math.Random().nextBool() ? 10 : -10));
        return true;
      }
    }

    return false;
  }
}

// Text object
class TextObject extends DrawableObject {
  String text;
  ui.Color color;
  double fontSize;
  bool isInteractive;

  TextObject({
    required this.text,
    required this.color,
    required this.fontSize,
    this.isInteractive = false,
  });

  @override
  ui.Size calculateSize(ui.Size minSize, ui.Size maxSize) {
    // Create a paragraph to measure text size
    final paragraphStyle = ui.ParagraphStyle();
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
      ..addText(text);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxSize.width));

    // Get the size of the text
    final textWidth = paragraph.maxIntrinsicWidth;
    final textHeight = paragraph.height;

    return ui.Size(
      math.min(math.max(textWidth, minSize.width), maxSize.width),
      math.min(math.max(textHeight, minSize.height), maxSize.height),
    );
  }

  @override
  void draw(ui.Canvas canvas) {
    final paragraphStyle = ui.ParagraphStyle();
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
      ..addText(text);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width));

    canvas.drawParagraph(paragraph, ui.Offset.zero);
  }

  @override
  bool handlePointerEvent(ui.Offset localPosition, ui.PointerData event) {
    if (!isInteractive) return false;

    // Handle pointer down event
    if (event.change == ui.PointerChange.down) {
      // Change text on tap
      text = "Tapped! ${DateTime.now().second}";
      return true;
    }

    return false;
  }
}

void main() {
  // Initialize Flutter binding
  ui.PlatformDispatcher.instance.onBeginFrame = null;
  ui.PlatformDispatcher.instance.onDrawFrame = null;

  // Create the vertical layout manager
  final layoutManager = VerticalLayoutManager();

  // Add objects to the layout manager
  layoutManager.addObject(RectangleObject(
    color: const ui.Color(0xFF4285F4), // Google Blue
    width: 200,
    height: 100,
    isInteractive: true,
  ));

  layoutManager.addObject(CircleObject(
    color: const ui.Color(0xFFEA4335), // Google Red
    radius: 50,
    isInteractive: true,
  ));

  layoutManager.addObject(TextObject(
    text: "Hello, dart:ui!",
    color: const ui.Color(0xFF34A853), // Google Green
    fontSize: 24,
    isInteractive: true,
  ));

  // Set up window callbacks
  ui.PlatformDispatcher.instance.onBeginFrame = (Duration timeStamp) {
    // Get the window size
    final window = ui.PlatformDispatcher.instance.views.first;
    final physicalSize = window.physicalSize;
    final devicePixelRatio = window.devicePixelRatio;

    // Set the layout constraints
    layoutManager.minSize = ui.Size.zero;
    layoutManager.maxSize = physicalSize;

    // Recalculate the layout
    layoutManager.layout();

    // Create a picture recorder and canvas
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Clear the canvas with a white background
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);

    // Draw the layout
    layoutManager.draw(canvas);

    // End recording and create a picture
    final picture = recorder.endRecording();

    // Create a scene
    final sceneBuilder = ui.SceneBuilder();
    sceneBuilder.pushTransform(Float64List.fromList([
      devicePixelRatio, 0, 0, 0,
      0, devicePixelRatio, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]));
    sceneBuilder.addPicture(ui.Offset.zero, picture);
    sceneBuilder.pop();

    // Build the scene
    final scene = sceneBuilder.build();

    // Render the scene
    window.render(scene);
  };

  // Set up pointer event handling
  ui.PlatformDispatcher.instance.onPointerDataPacket = (ui.PointerDataPacket packet) {
    for (final event in packet.data) {
      if (layoutManager.handlePointerEvent(event)) {
        // Request a new frame if an event was handled
        ui.PlatformDispatcher.instance.scheduleFrame();
      }
    }
  };

  // Schedule the first frame
  ui.PlatformDispatcher.instance.scheduleFrame();
}
