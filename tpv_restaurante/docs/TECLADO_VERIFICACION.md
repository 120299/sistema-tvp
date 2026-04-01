# DIAGRAMA DE VERIFICACIÓN - TECLADO VIRTUAL TPV

## Escenario 1: Campo de texto editable NORMAL
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 1                                  │
│              Campo de texto editable (TextField)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Widget: TextField(                                                 │
│    controller: _buscadorController,  ← Válido                      │
│    readOnly: false,               ← Válido                        │
│    enabled: true,                  ← Válido                        │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                           │
│              │ ¿readOnly == true?      │ → NO → Continuar           │
│              └────────────────────────┘                             │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                           │
│              │ ¿enabled == false?      │ → NO → Continuar           │
│              └────────────────────────┘                             │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                           │
│              │ ¿controller != null?    │ → SÍ → MOSTRAR TECLADO     │
│              └────────────────────────┘                             │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual se MUESTRA               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 2: Campo de texto de SOLO LECTURA
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 2                                  │
│              Campo de texto readOnly (TextField)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Widget: TextField(                                                 │
│    controller: _controller,        ← Válido                        │
│    readOnly: true,                ← ❌ BLOQUEO                     │
│    enabled: true,                                                    │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ ¿readOnly == true?      │ → SÍ → OCULTAR TECLADO    │
│              └────────────────────────┘  y RETURN                   │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual NO se muestra            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 3: Campo de texto DESHABILITADO
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 3                                  │
│              Campo de texto disabled (TextField)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Widget: TextField(                                                 │
│    controller: _controller,                                          │
│    readOnly: false,                                                  │
│    enabled: false,                ← ❌ BLOQUEO                     │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ ¿enabled == false?      │ → SÍ → OCULTAR TECLADO    │
│              └────────────────────────┘  y RETURN                   │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual NO se muestra            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 4: TextFormField deshabilitado
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 4                                  │
│              TextFormField disabled                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Widget: TextFormField(                                              │
│    controller: _formController,                                       │
│    enabled: false,                ← ❌ BLOQUEO                     │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ ¿enabled == false?      │ → SÍ → OCULTAR TECLADO    │
│              └────────────────────────┘  y RETURN                   │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual NO se muestra            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 5: EditableText de solo lectura
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 5                                  │
│              EditableText readOnly                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Widget: EditableText(                                              │
│    controller: _controller,                                            │
│    readOnly: true,                ← ❌ BLOQUEO                     │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ ¿readOnly == true?     │ → SÍ → OCULTAR TECLADO    │
│              └────────────────────────┘  y RETURN                   │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual NO se muestra            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 6: Sin campo de texto en foco
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 6                                  │
│              Ningún campo de texto en foco                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  primaryFocus = null                                               │
│         │                                                          │
│         ▼                                                          │
│  ┌─────────────────────────────────┐                               │
│  │ ¿primaryFocus == null?          │ → SÍ → OCULTAR TECLADO       │
│  └─────────────────────────────────┘  y RETURN                       │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual NO se muestra            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Escenario 7: Widget complejo (Dialog) con TextField
```
┌─────────────────────────────────────────────────────────────────────┐
│                         ESCENARIO 7                                  │
│              Dialog/Widget con TextField anidado                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  AlertDialog(                                                        │
│    content: Column(                                                  │
│      children: [                                                     │
│        TextField(                   ← El TextField real            │
│          controller: _precioController,                              │
│          readOnly: false,                                           │
│          enabled: true,                                              │
│        )                                                            │
│      ]                                                              │
│    )                                                                │
│  )                                                                 │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ _findControllerInElement│                            │
│              │ (búsqueda recursiva)   │                             │
│              └────────────────────────┘                             │
│                           │                                          │
│                           ▼                                          │
│  ┌───────────────────────────────────────────────────────────┐     │
│  │ Recorre el árbol de widgets buscando:                     │     │
│  │ - TextField con controller válido                        │     │
│  │ - TextFormField con controller válido                   │     │
│  │ - EditableText con controller válido                    │     │
│  │                                                         │     │
│  │ ⚠️ IMPORTANTE: También verifica readOnly y enabled     │     │
│  └───────────────────────────────────────────────────────────┘     │
│                           │                                          │
│                           ▼                                          │
│              ┌────────────────────────┐                             │
│              │ ¿Controller encontrado│ → SÍ → MOSTRAR TECLADO      │
│              └────────────────────────┘                             │
│                                                                      │
│  ✓ RESULTADO ESPERADO: El teclado virtual se muestra en dialogs   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## FLUJO COMPLETO DEL TECLADO

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO DE VERIFICACIÓN                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. USUARIO Toca un campo de texto                                      │
│         │                                                                │
│         ▼                                                                │
│  2. Flutter asigna foco al TextField                                    │
│         │                                                                │
│         ▼                                                                │
│  3. FocusManager.instance.primaryFocus se actualiza                      │
│         │                                                                │
│         ▼                                                                │
│  4. AppKeyboardOverlay detecta el cambio de foco                         │
│     (_checkForTextFieldFocus se ejecuta)                                 │
│         │                                                                │
│         ▼                                                                │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    VALIDACIONES                                  │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  ┌─────────────────────┐                                         │  │
│  │  │ keyboardSettings.   │ NO ──→ Ocultar teclado, RETURN        │  │
│  │  │ useVirtualKeyboard?  │                                         │  │
│  │  └─────────────────────┘                                         │  │
│  │          │ Sí                                                    │  │
│  │          ▼                                                       │  │
│  │  ┌─────────────────────┐                                         │  │
│  │  │ ¿Es TextField?     │                                         │  │
│  │  └─────────────────────┘                                         │  │
│  │          │                                                        │  │
│  │    ┌─────┴─────┐                                                 │  │
│  │    │ Sí        │ No                                               │  │
│  │    ▼           ▼                                                   │  │
│  │ ┌──────────┐ ┌─────────────────────┐                            │  │
│  │ │readOnly?  │ │ ¿Es TextFormField? │                            │  │
│  │ └─────┬────┘ └─────────┬───────────┘                            │  │
│  │       │                  │                                         │  │
│  │  ┌────┴────┐     ┌─────┴─────┐                                  │  │
│  │  │ NO│SI    │     │ NO│Sí      │                                  │  │
│  │  ▼  ▼       │     ▼  ▼         │                                  │  │
│  │ SI→RETORN   │    SI→RETORN      │                                  │  │
│  │  │NO        │     │NO           │                                  │  │
│  │  ▼          │     ▼             │                                  │  │
│  │ ┌────────┐ │  ┌────────────┐ │                                 │  │
│  │ │enabled?│ │  │enabled?    │ │                                 │  │
│  │ └───┬────┘ │  └──────┬─────┘ │                                 │  │
│  │     │NO    │         │NO      │                                 │  │
│  │     ▼      │         ▼        │                                 │  │
│  │   RETURN   │       RETURN     │                                 │  │
│  │     │NO    │         │NO     │                                 │  │
│  │     │      │         │       │                                 │  │
│  │     ▼      │         ▼       │                                 │  │
│  │   ✓ OK     │       ✓ OK      │                                 │  │
│  └─────┼──────┘         ├───────┘                                 │  │
│        │                │                                          │  │
│        └───────┬────────┘                                         │  │
│                │                                                    │  │
│                ▼                                                    │  │
│  ┌─────────────────────────────┐                                    │  │
│  │ ¿controller != null?       │ NO ──→ RETURN (no mostrar)       │  │
│  └─────────────┬─────────────┘                                    │  │
│                │ Sí                                                  │  │
│                ▼                                                     │  │
│  ┌─────────────────────────────┐                                    │  │
│  │ ¿controller cambió?        │ NO ──→ No hacer nada              │  │
│  └─────────────┬─────────────┘                                    │  │
│                │ Sí                                                  │  │
│                ▼                                                     │  │
│         ┌──────────────┐                                             │  │
│         │ MOSTRAR      │                                             │  │
│         │ TECLADO      │                                             │  │
│         └──────────────┘                                             │  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## CHECKLIST DE PRUEBA

### ✓ Campos donde DEBERÍA aparecer el teclado:
- [ ] Campo de búsqueda en pantalla de productos (TextField)
- [ ] Campo de búsqueda en venta libre (TextField)
- [ ] Campo de precio en diálogo de editar precio (TextField)
- [ ] Campos de texto en Setup (TextFormField)
- [ ] Campos de login (TextFormField)
- [ ] Campos en configuración del negocio (TextFormField)

### ✓ Campos donde NO debería aparecer el teclado:
- [ ] Etiquetas de texto mostradas (no son TextField)
- [ ] Botones con texto (no son TextField)
- [ ] Campos readOnly: true
- [ ] Campos enabled: false
- [ ] Listas de productos (tap en producto, no en campo de texto)
- [ ] Tap en fondo de pantalla

## COMANDOS DE DEBUG

Para verificar que funciona, añade estos prints en el código:

```dart
// En _checkForTextFieldFocus(), después de encontrar un controller válido:
print('🔑 TECLADO: Mostrando para ${focusedWidget.runtimeType}');
print('   - Controller: ${controller}');
print('   - Text: "${controller.text}"');

// Cuando se oculta:
print('🔒 TECLADO: Ocultando');
```

## CÓDIGO IMPLEMENTADO

El archivo `lib/core/widgets/app_keyboard_overlay.dart` contiene:

1. **Validación de TextField** (línea 90-95):
```dart
if (focusedWidget is TextField) {
  final textField = focusedWidget as TextField;
  if (textField.readOnly == true || textField.enabled == false) {
    return; // No mostrar teclado
  }
  controller = textField.controller;
}
```

2. **Validación de TextFormField** (línea 96-101):
```dart
if (focusedWidget is TextFormField) {
  final formField = focusedWidget as TextFormField;
  if (formField.enabled == false) {
    return; // No mostrar teclado
  }
  controller = formField.controller;
}
```

3. **Validación de EditableText** (línea 102-107):
```dart
if (focusedWidget is EditableText) {
  final editable = focusedWidget as EditableText;
  if (editable.readOnly == true) {
    return; // No mostrar teclado
  }
  controller = editable.controller;
}
```

4. **Búsqueda recursiva en widgets hijos** (_findControllerInElement, línea 123-149):
```dart
TextEditingController? _findControllerInElement(Element element) {
  // ...validaciones de readOnly y enabled...
  
  // Búsqueda recursiva en hijos
  element.visitChildElements((child) {
    result = _findControllerInElement(child);
  });
  
  return result;
}
```
