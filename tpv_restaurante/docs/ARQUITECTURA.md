# TPV Restaurante - Documentación de Arquitectura

## Resumen Ejecutivo

Este documento describe cómo funciona el sistema de almacenamiento y gestión de datos del TPV Restaurante.

---

## 1. Tecnología de Almacenamiento

### Hive (Base de datos local)

El sistema utiliza **Hive** como base de datos local. Hive es una base de datos NoSQL rápida y ligera para Flutter que almacena datos en archivos locales en el dispositivo.

**Ventajas:**
- Velocidad: Acceso a datos en milisegundos
- Simplicidad: No requiere servidor externo
- Portabilidad: Los datos se almacenan localmente
- Offline: Funciona sin conexión a internet

---

## 2. Estructura de Datos

### 2.1 Modelos Principales

```
┌────────────────────────────────────────────────────────────────────┐
│                         MODELOS DE DATOS                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                   │
│  │  CAJERO  │     │   CAJA   │     │  PEDIDO │                   │
│  ├──────────┤     ├──────────┤     ├──────────┤                   │
│  │ • id     │     │ • id     │     │ • id     │                   │
│  │ • nombre │     │ • cajeroId│────▶│ • cajeroId│                  │
│  │ • pin    │     │ • estado │     │ • clienteId│◀─────┐          │
│  │ • rol    │     │ • fondo  │     │ • mesaId  │       │          │
│  │ • activo │     │ • ventas │     │ • items[] │       │          │
│  └──────────┘     │ • movims │     │ • estado  │       │          │
│       │           └──────────┘     │ • total   │       │          │
│       │              │             └──────────┘       │          │
│       │              │                   │            │          │
│       │              ▼                   ▼            │          │
│       │        ┌──────────┐     ┌──────────┐       │          │
│       │        │MOVIMIENTO│     │ CLIENTE  │       │          │
│       │        ├──────────┤     ├──────────┤       │          │
│       └───────▶│ • tipo   │     │ • id     │───────┘          │
│                │ • cantidad│     │ • nombre │                   │
│                │ • fecha  │     │ • nif    │                   │
│                │ • pedidoId│     │ • telefono                │
│                └──────────┘     │ • direccion                │
│                                  │ • totalPedidos            │
│                                  │ • totalGastado            │
│                                  └──────────┘                 │
│                                                                     │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐               │
│  │ PRODUCTO  │────▶│CATEGORÍA │     │  MESA   │               │
│  ├──────────┤     ├──────────┤     ├──────────┤               │
│  │ • id     │     │ • id     │     │ • id     │               │
│  │ • nombre │     │ • nombre │     │ • numero │               │
│  │ • precio │     │ • icono  │     │ • estado │               │
│  │ • categoriaId                   │ • capacidad              │
│  │ • disponible                   └──────────┘                │
│  └──────────┘                                                    │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### 2.2 Descripción de Modelos

#### Cajero (Usuario del sistema)
```dart
- id: Identificador único
- nombre: Nombre completo del usuario
- pin: PIN de 4 dígitos (para login)
- rol: ADMINISTRADOR o CAJERO
- activo: true/false (para habilitar/deshabilitar)
- fechaCreacion: Fecha de registro
```

**Archivos relacionados:**
- Modelo: `lib/data/models/cajero.dart`
- Provider: `cajerosProvider` en `providers.dart`

#### Cliente
```dart
- id: Identificador único
- nombre: Nombre/Razón social
- telefono: Teléfono de contacto
- email: Correo electrónico
- nif: NIF/CIF/NIE (para facturación)
- direccion: Calle y número
- codigoPostal: Código postal
- poblacion: Ciudad/Municipio
- totalPedidos: Contador de pedidos (se actualiza automáticamente)
- totalGastado: Suma de importes de pedidos (se actualiza automáticamente)
```

**Archivos relacionados:**
- Modelo: `lib/data/models/cliente.dart`
- Provider: `clientesProvider` en `providers.dart`

#### Pedido
```dart
- id: Identificador único
- mesaId: ID de la mesa (si aplica)
- items[]: Lista de productos vendidos
- estado: ABIERTO, ENVIADO, PREPARANDO, LISTO, CERRADO, CANCELADO
- cajeroId: ID del cajero que atendió
- cajeroNombre: Nombre del cajero (para consulta rápida)
- clienteId: ID del cliente (si se seleccionó)
- clienteNombre: Nombre del cliente (para consulta rápida)
- metodoPago: Efectivo, Tarjeta, Mixto
- porcentajePropina: % de propina
- descuento: Importe de descuento
- horaApertura: Fecha/hora de creación
- horaCierre: Fecha/hora de cobro
- numeroPersonas: Para dividir cuenta
```

**Archivos relacionados:**
- Modelo: `lib/data/models/pedido.dart`
- Provider: `pedidosProvider` en `providers.dart`

#### Caja
```dart
- id: Identificador único
- cajeroId: ID del cajero que abrió la caja
- cajeroNombre: Nombre del cajero
- estado: ABIERTA o CERRADA
- fondoInicial: Dinero con el que se abrió
- totalVentas: Suma total de ventas del día
- totalEfectivo: Ventas pagadas en efectivo
- totalTarjeta: Ventas pagadas con tarjeta
- movimientos[]: Lista de ingresos/retiros
- fechaApertura: Cuando se abrió
- fechaCierre: Cuando se cerró
- saldoFinal: Cantidad al cerrar
```

**Cálculo de saldo:**
```dart
saldoCaja = fondoInicial + totalEfectivo + ingresos - retiros
```

**Archivos relacionados:**
- Modelo: `lib/data/models/caja.dart`
- Provider: `cajaProvider` en `providers.dart`

#### MovimientoCaja
```dart
- id: Identificador único
- tipo: "venta", "ingreso", "retiro"
- cantidad: Importe
- descripcion: Concepto (opcional)
- metodoPago: Efectivo, Tarjeta (para ventas)
- fecha: Fecha/hora del movimiento
- pedidoId: ID del pedido (para ventas)
```

---

## 3. Flujo de una Venta

```
┌──────────────────────────────────────────────────────────────────────┐
│                         FLUJO DE VENTA                                │
└──────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ 1. LOGIN     │
    │   Usuario     │
    │   introduce   │
    │   PIN         │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Cajero        │──────▶ Se guarda en cajeroActualProvider
    │ autenticado   │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 2. ABRIR     │
    │    CAJA       │──────▶ cajaProvider.abrirCaja()
    │    (opcional) │        Se registra cajeroId
    └──────┬───────┘        Se guarda fondo inicial
           │
           ▼
    ┌──────────────┐
    │ 3. CREAR     │
    │    PEDIDO     │──────▶ pedidosProvider.crear()
    │               │        Se guarda mesaId, cajeroId
    └──────┬───────┘        Estado inicial: ABIERTO
           │
           ▼
    ┌──────────────┐
    │ 4. AGREGAR   │
    │    PRODUCTOS  │──────▶ pedidosProvider.agregarItem()
    │               │        Se añaden items al pedido
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 5. SELECCIONAR│──────▶ Opcional: cliente
    │    CLIENTE   │        Se vincula clienteId
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ 6. COBRAR    │──────▶ Se muestra total + IVA
    │    (PAGO)     │        Se elige método de pago
    └──────┬───────┘        Se calcula cambio (si aplica)
           │
           ▼
    ┌──────────────┐
    │ 7. CERRAR    │
    │    PEDIDO     │──────▶ pedidosProvider.cerrar()
    │               │        Estado: CERRADO
    └──────┬───────┘        Se guarda metodoPago
           │                 Se guarda horaCierre
           ▼
    ┌──────────────┐
    │ 8. REGISTRAR│──────▶ cajaProvider.registrarVenta()
    │    EN CAJA   │        Movimiento de tipo "venta"
    └──────┬───────┘        Se actualiza totalEfectivo/totalTarjeta
           │
           ▼
    ┌──────────────┐
    │ 9. ACTUALIZAR│──────▶ clientesProvider.registrarVenta()
    │    CLIENTE   │        Se incrementa totalPedidos
    └──────┬───────┘        Se suma importe a totalGastado
           │
           ▼
    ┌──────────────┐
    │ 10. IMPRIMIR│──────▶ PrintService.printTicket()
    │     TICKET    │        Datos del negocio
    └──────┬───────┘        Items vendidos
           │                 Base imponible + IVA
           ▼                 Total
    ┌──────────────┐
    │ 11. LIBERAR │──────▶ mesasProvider.liberar()
    │    MESA      │        Estado: LIBRE
    └──────────────┘
```

---

## 4. Boxes de Hive

Los "boxes" son los contenedores donde Hive almacena los datos:

| Box | Tipo | Descripción |
|-----|------|-------------|
| `productosBox` | `Box<Producto>` | Catálogo de productos |
| `categoriasBox` | `Box<CategoriaProducto>` | Categorías del menú |
| `mesasBox` | `Box<Mesa>` | Mesas del restaurante |
| `pedidosBox` | `Box<Pedido>` | **Todos los pedidos (histórico completo)** |
| `negocioBox` | `Box<DatosNegocio>` | Datos fiscales (solo 1 registro) |
| `cajaBox` | `Box<Caja>` | Sesiones de caja |
| `cajerosBox` | `Box<Cajero>` | Usuarios del sistema |
| `clientesBox` | `Box<Cliente>` | Base de clientes |

**Archivo:** `lib/data/services/database_service.dart`

---

## 5. Providers (Estado Global)

Los providers manejan el estado de la aplicación usando Riverpod:

```dart
// Providers principales
cajerosProvider        → Lista de usuarios
cajeroActualProvider   → Usuario logueado actualmente
clientesProvider       → Lista de clientes
negocioProvider        → Datos del negocio
productosProvider      → Lista de productos
categoriasProvider     → Categorías
mesasProvider          → Mesas
pedidosProvider        → Pedidos
cajaProvider           → Caja actual
indiceNavegacionProvider → Pestaña activa
isLoggedInProvider     → Sesión iniciada
```

**Archivo:** `lib/presentation/providers/providers.dart`

---

## 6. Backup y Restauración

### Crear Backup
```dart
BackupService.crearBackup()
```
Genera un archivo JSON con todos los datos:
- negocio
- cajeros
- clientes
- productos
- categorías
- mesas
- pedidos

**Ubicación:** Documents del dispositivo
**Nombre:** `backup_tpv_YYYYMMDD_HHMMSS.json`

### Restaurar Backup
```dart
BackupService.restaurarBackup(ruta)
```
Importa datos desde un archivo JSON previamente exportado.

**Archivo:** `lib/data/services/backup_service.dart`

---

## 7. Cálculos Fiscales

### IVA
El sistema calcula el IVA según la normativa española:

```dart
subtotal = suma de (cantidad × precio unitario)
impuesto = subtotal × 0.21  // 21% IVA
total = subtotal + impuesto
```

**Base imponible:** subtotal (sin IVA)
**Importe IVA:** subtotal × 21%
**Total:** subtotal + IVA

### Ticket
El ticket incluye:
- Datos del negocio (nombre, dirección, CIF)
- Número de ticket
- Fecha y hora
- Lista de productos
- Base imponible
- Importe IVA
- Total
- Método de pago
- Datos del cliente (si existe)

---

## 8. Seguridad

### Login
1. Usuario selecciona su nombre
2. Introduce PIN de 4 dígitos
3. Sistema verifica contra el PIN almacenado
4. Si es correcto, guarda sesión en `cajeroActualProvider`

### Permisos
- **Administradores**: Pueden cerrar caja, gestionar usuarios
- **Cajeros**: Solo pueden hacer ventas

### Logout
Al cerrar sesión:
1. Se limpia `cajeroActualProvider`
2. Se limpia `isLoggedInProvider`
3. Se muestra pantalla de login

---

## 9. Archivos Clave

| Archivo | Propósito |
|---------|----------|
| `database_service.dart` | Inicialización de Hive |
| `providers.dart` | Estado global de la app |
| `backup_service.dart` | Exportar/importar datos |
| `print_service.dart` | Generación de tickets PDF |
| `main.dart` | Punto de entrada |

---

## 10. Próximas Mejoras Sugeridas

1. **Sincronización en la nube** - Implementar Firebase/Supabase
2. **Backup automático** - Programar backups periódicos
3. **Reportes avanzados** - Gráficos de ventas, horarios pico
4. **Gestión de inventario** - Control de stock
5. **Integración fiscal** - Conexión con AEAT

---

*Documento generado: ${DateTime.now().toString()}*
