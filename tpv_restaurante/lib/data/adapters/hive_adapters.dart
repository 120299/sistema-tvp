import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class CategoriaProductoAdapter extends TypeAdapter<CategoriaProducto> {
  @override
  final int typeId = 0;

  @override
  CategoriaProducto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoriaProducto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      icono: fields[2] as String,
      color: Color(fields[3] as int),
      imagenUrl: fields[4] as String?,
      orden: fields[5] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CategoriaProducto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.icono)
      ..writeByte(3)
      ..write(obj.color.toARGB32())
      ..writeByte(4)
      ..write(obj.imagenUrl)
      ..writeByte(5)
      ..write(obj.orden);
  }
}

class ProductoAdapter extends TypeAdapter<Producto> {
  @override
  final int typeId = 1;

  @override
  Producto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Producto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      precio: fields[2] as double,
      categoriaId: fields[3] as String,
      imagenUrl: fields[4] as String?,
      disponible: fields[5] as bool? ?? true,
      descripcion: fields[6] as String?,
      precioCompra: fields[7] as double?,
      esAlergenico: fields[8] as bool? ?? false,
      codigoBarras: fields[9] as String?,
      esVariable: fields[10] as bool? ?? false,
      variantes: (fields[11] as List?)?.map((v) {
        final map = Map<String, dynamic>.from(v as Map);
        return VarianteProducto.fromJson(map);
      }).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, Producto obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.precio)
      ..writeByte(3)
      ..write(obj.categoriaId)
      ..writeByte(4)
      ..write(obj.imagenUrl)
      ..writeByte(5)
      ..write(obj.disponible)
      ..writeByte(6)
      ..write(obj.descripcion)
      ..writeByte(7)
      ..write(obj.precioCompra)
      ..writeByte(8)
      ..write(obj.esAlergenico)
      ..writeByte(9)
      ..write(obj.codigoBarras)
      ..writeByte(10)
      ..write(obj.esVariable)
      ..writeByte(11)
      ..write(obj.variantes?.map((v) => v.toJson()).toList());
  }
}

class MesaAdapter extends TypeAdapter<Mesa> {
  @override
  final int typeId = 2;

  @override
  Mesa read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mesa(
      id: fields[0] as String,
      numero: fields[1] as int,
      capacidad: fields[2] as int,
      estado: EstadoMesa.values[fields[3] as int],
      pedidoActualId: fields[4] as String?,
      horaApertura: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Mesa obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.numero)
      ..writeByte(2)
      ..write(obj.capacidad)
      ..writeByte(3)
      ..write(obj.estado.index)
      ..writeByte(4)
      ..write(obj.pedidoActualId)
      ..writeByte(5)
      ..write(obj.horaApertura);
  }
}

class PedidoItemAdapter extends TypeAdapter<PedidoItem> {
  @override
  final int typeId = 3;

  @override
  PedidoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PedidoItem(
      id: fields[0] as String,
      productoId: fields[1] as String,
      varianteId: fields[2] as String?,
      productoNombre: fields[3] as String,
      cantidad: fields[4] as int,
      precioUnitario: fields[5] as double,
      notas: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PedidoItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productoId)
      ..writeByte(2)
      ..write(obj.varianteId)
      ..writeByte(3)
      ..write(obj.productoNombre)
      ..writeByte(4)
      ..write(obj.cantidad)
      ..writeByte(5)
      ..write(obj.precioUnitario)
      ..writeByte(6)
      ..write(obj.notas);
  }
}

class PedidoAdapter extends TypeAdapter<Pedido> {
  @override
  final int typeId = 4;

  @override
  Pedido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pedido(
      id: fields[0] as String,
      mesaId: fields[1] as String,
      items: (fields[2] as List).cast<PedidoItem>(),
      estado: EstadoPedido.values[fields[3] as int],
      mesero: fields[4] as String?,
      horaApertura: fields[5] as DateTime?,
      horaCierre: fields[6] as DateTime?,
      metodoPago: fields[7] as String?,
      porcentajePropina: fields[8] as double? ?? 0,
      descuento: fields[9] as double? ?? 0,
      numeroPersonas: fields[10] as int?,
      cajeroId: fields[11] as String?,
      cajeroNombre: fields[12] as String?,
      clienteId: fields[13] as String?,
      clienteNombre: fields[14] as String?,
      numeroTicket: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Pedido obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mesaId)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.estado.index)
      ..writeByte(4)
      ..write(obj.mesero)
      ..writeByte(5)
      ..write(obj.horaApertura)
      ..writeByte(6)
      ..write(obj.horaCierre)
      ..writeByte(7)
      ..write(obj.metodoPago)
      ..writeByte(8)
      ..write(obj.porcentajePropina)
      ..writeByte(9)
      ..write(obj.descuento)
      ..writeByte(10)
      ..write(obj.numeroPersonas)
      ..writeByte(11)
      ..write(obj.cajeroId)
      ..writeByte(12)
      ..write(obj.cajeroNombre)
      ..writeByte(13)
      ..write(obj.clienteId)
      ..writeByte(14)
      ..write(obj.clienteNombre)
      ..writeByte(15)
      ..write(obj.numeroTicket);
  }
}

class DatosNegocioAdapter extends TypeAdapter<DatosNegocio> {
  @override
  final int typeId = 5;

  @override
  DatosNegocio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DatosNegocio(
      nombre: fields[0] as String? ?? 'Mi Restaurante',
      slogan: fields[1] as String?,
      direccion: fields[2] as String? ?? '',
      ciudad: fields[3] as String? ?? '',
      telefono: fields[4] as String? ?? '',
      email: fields[5] as String?,
      cifNif: fields[6] as String?,
      website: fields[7] as String?,
      ivaPorcentaje: fields[8] as double? ?? 10.0,
      imprimeLogo: fields[9] as bool? ?? true,
      logoBase64: fields[10] as String?,
      razonSocial: fields[11] as String?,
      numeroSerie: fields[12] as String?,
      numeroLicencia: fields[13] as String?,
      actividad: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DatosNegocio obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.slogan)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.ciudad)
      ..writeByte(4)
      ..write(obj.telefono)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.cifNif)
      ..writeByte(7)
      ..write(obj.website)
      ..writeByte(8)
      ..write(obj.ivaPorcentaje)
      ..writeByte(9)
      ..write(obj.imprimeLogo)
      ..writeByte(10)
      ..write(obj.logoBase64)
      ..writeByte(11)
      ..write(obj.razonSocial)
      ..writeByte(12)
      ..write(obj.numeroSerie)
      ..writeByte(13)
      ..write(obj.numeroLicencia)
      ..writeByte(14)
      ..write(obj.actividad);
  }
}

class MovimientoCajaAdapter extends TypeAdapter<MovimientoCaja> {
  @override
  final int typeId = 6;

  @override
  MovimientoCaja read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovimientoCaja(
      id: fields[0] as String,
      tipo: fields[1] as String,
      cantidad: fields[2] as double,
      descripcion: fields[3] as String?,
      metodoPago: fields[4] as String?,
      fecha: fields[5] as DateTime,
      pedidoId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MovimientoCaja obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.cantidad)
      ..writeByte(3)
      ..write(obj.descripcion)
      ..writeByte(4)
      ..write(obj.metodoPago)
      ..writeByte(5)
      ..write(obj.fecha)
      ..writeByte(6)
      ..write(obj.pedidoId);
  }
}

class CajeroAdapter extends TypeAdapter<Cajero> {
  @override
  final int typeId = 8;

  @override
  Cajero read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cajero(
      id: fields[0] as String,
      nombre: fields[1] as String,
      pin: fields[2] as String?,
      fechaCreacion: fields[3] as DateTime,
      activo: fields[4] as bool? ?? true,
      rol: fields[5] != null
          ? RolCajero.values[fields[5] as int]
          : RolCajero.cajero,
    );
  }

  @override
  void write(BinaryWriter writer, Cajero obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.pin)
      ..writeByte(3)
      ..write(obj.fechaCreacion)
      ..writeByte(4)
      ..write(obj.activo)
      ..writeByte(5)
      ..write(obj.rol.index);
  }
}

class ClienteAdapter extends TypeAdapter<Cliente> {
  @override
  final int typeId = 9;

  @override
  Cliente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cliente(
      id: fields[0] as String,
      nombre: fields[1] as String,
      telefono: fields[2] as String?,
      email: fields[3] as String?,
      observaciones: fields[4] as String?,
      fechaCreacion: fields[5] as DateTime,
      totalPedidos: fields[6] as int? ?? 0,
      totalGastado: fields[7] as double? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Cliente obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.telefono)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.observaciones)
      ..writeByte(5)
      ..write(obj.fechaCreacion)
      ..writeByte(6)
      ..write(obj.totalPedidos)
      ..writeByte(7)
      ..write(obj.totalGastado);
  }
}

class CajaAdapter extends TypeAdapter<Caja> {
  @override
  final int typeId = 7;

  @override
  Caja read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Caja(
      id: fields[0] as String,
      fechaApertura: fields[1] as DateTime,
      fechaCierre: fields[2] as DateTime?,
      fondoInicial: fields[3] as double? ?? 0,
      totalVentas: fields[4] as double? ?? 0,
      totalEfectivo: fields[5] as double? ?? 0,
      totalTarjeta: fields[6] as double? ?? 0,
      movimientos: (fields[7] as List?)?.cast<MovimientoCaja>() ?? [],
      estado: EstadoCaja.values[fields[8] as int? ?? 0],
      saldoFinal: fields[9] as double?,
      cajeroId: fields[10] as String?,
      cajeroNombre: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Caja obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fechaApertura)
      ..writeByte(2)
      ..write(obj.fechaCierre)
      ..writeByte(3)
      ..write(obj.fondoInicial)
      ..writeByte(4)
      ..write(obj.totalVentas)
      ..writeByte(5)
      ..write(obj.totalEfectivo)
      ..writeByte(6)
      ..write(obj.totalTarjeta)
      ..writeByte(7)
      ..write(obj.movimientos)
      ..writeByte(8)
      ..write(obj.estado.index)
      ..writeByte(9)
      ..write(obj.saldoFinal)
      ..writeByte(10)
      ..write(obj.cajeroId)
      ..writeByte(11)
      ..write(obj.cajeroNombre);
  }
}
