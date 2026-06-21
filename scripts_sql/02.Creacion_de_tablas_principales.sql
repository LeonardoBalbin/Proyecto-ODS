-- 2. Creación de las tablas, relaciones y restricciones

CREATE TABLE ROL
(
    id_rol      INT IDENTITY(1,1) NOT NULL,
    nombre      VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200) NULL,

    CONSTRAINT PK_ROL PRIMARY KEY (id_rol),
    CONSTRAINT UQ_ROL_nombre UNIQUE (nombre)
);
GO

CREATE TABLE USUARIO
(
    id_usuario    INT IDENTITY(1,1) NOT NULL,
    id_rol        INT NOT NULL,
    nombres       VARCHAR(100) NOT NULL,
    apellidos     VARCHAR(100) NOT NULL,
    correo        VARCHAR(150) NOT NULL,
    contrasena    VARCHAR(255) NOT NULL,
    estado_usuario VARCHAR(20) NOT NULL
        CONSTRAINT DF_USUARIO_estado DEFAULT ('ACTIVO'),

    CONSTRAINT PK_USUARIO PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_USUARIO_correo UNIQUE (correo),
    CONSTRAINT CK_USUARIO_estado CHECK
        (estado_usuario IN ('ACTIVO', 'INACTIVO', 'BLOQUEADO')),
    CONSTRAINT FK_USUARIO_ROL FOREIGN KEY (id_rol)
        REFERENCES ROL (id_rol)
);
GO

CREATE TABLE PACIENTE
(
    id_paciente       INT IDENTITY(1,1) NOT NULL,
    id_usuario        INT NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    telefono          VARCHAR(20) NULL,
    informacion_medica VARCHAR(MAX) NULL,

    CONSTRAINT PK_PACIENTE PRIMARY KEY (id_paciente),
    CONSTRAINT UQ_PACIENTE_id_usuario UNIQUE (id_usuario),
    CONSTRAINT FK_PACIENTE_USUARIO FOREIGN KEY (id_usuario)
        REFERENCES USUARIO (id_usuario)
);
GO

CREATE TABLE MEDICO
(
    id_medico          INT IDENTITY(1,1) NOT NULL,
    id_usuario         INT NOT NULL,
    especialidad       VARCHAR(100) NOT NULL,
    numero_colegiatura VARCHAR(30) NOT NULL,

    CONSTRAINT PK_MEDICO PRIMARY KEY (id_medico),
    CONSTRAINT UQ_MEDICO_id_usuario UNIQUE (id_usuario),
    CONSTRAINT UQ_MEDICO_numero_colegiatura UNIQUE (numero_colegiatura),
    CONSTRAINT FK_MEDICO_USUARIO FOREIGN KEY (id_usuario)
        REFERENCES USUARIO (id_usuario)
);
GO

CREATE TABLE TRATAMIENTO
(
    id_tratamiento    INT IDENTITY(1,1) NOT NULL,
    id_paciente       INT NOT NULL,
    id_medico         INT NOT NULL,
    nombre            VARCHAR(100) NOT NULL,
    descripcion       VARCHAR(500) NULL,
    fecha_inicio      DATE NOT NULL,
    fecha_fin         DATE NULL,
    estado_tratamiento VARCHAR(20) NOT NULL
        CONSTRAINT DF_TRATAMIENTO_estado DEFAULT ('ACTIVO'),

    CONSTRAINT PK_TRATAMIENTO PRIMARY KEY (id_tratamiento),
    CONSTRAINT CK_TRATAMIENTO_fechas CHECK
        (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT CK_TRATAMIENTO_estado CHECK
        (estado_tratamiento IN
            ('ACTIVO', 'FINALIZADO', 'SUSPENDIDO', 'CANCELADO')),
    CONSTRAINT FK_TRATAMIENTO_PACIENTE FOREIGN KEY (id_paciente)
        REFERENCES PACIENTE (id_paciente),
    CONSTRAINT FK_TRATAMIENTO_MEDICO FOREIGN KEY (id_medico)
        REFERENCES MEDICO (id_medico)
);
GO

CREATE TABLE MEDICAMENTO
(
    id_medicamento INT IDENTITY(1,1) NOT NULL,
    nombre         VARCHAR(100) NOT NULL,
    descripcion    VARCHAR(500) NULL,
    presentacion   VARCHAR(100) NOT NULL,

    CONSTRAINT PK_MEDICAMENTO PRIMARY KEY (id_medicamento)
);
GO

CREATE TABLE PRESCRIPCION
(
    id_prescripcion INT IDENTITY(1,1) NOT NULL,
    id_tratamiento  INT NOT NULL,
    id_medicamento  INT NOT NULL,
    dosis           DECIMAL(10,2) NOT NULL,
    unidad_medida   VARCHAR(30) NOT NULL,
    frecuencia      VARCHAR(100) NOT NULL,
    duracion_dias   INT NOT NULL,
    indicaciones    VARCHAR(500) NULL,

    CONSTRAINT PK_PRESCRIPCION PRIMARY KEY (id_prescripcion),
    CONSTRAINT CK_PRESCRIPCION_dosis CHECK (dosis > 0),
    CONSTRAINT CK_PRESCRIPCION_duracion CHECK (duracion_dias > 0),
    CONSTRAINT FK_PRESCRIPCION_TRATAMIENTO FOREIGN KEY (id_tratamiento)
        REFERENCES TRATAMIENTO (id_tratamiento),
    CONSTRAINT FK_PRESCRIPCION_MEDICAMENTO FOREIGN KEY (id_medicamento)
        REFERENCES MEDICAMENTO (id_medicamento)
);
GO

CREATE TABLE HORARIO_DOSIS
(
    id_horario      INT IDENTITY(1,1) NOT NULL,
    id_prescripcion INT NOT NULL,
    hora_programada TIME(0) NOT NULL,

    CONSTRAINT PK_HORARIO_DOSIS PRIMARY KEY (id_horario),
    CONSTRAINT UQ_HORARIO_DOSIS_prescripcion_hora
        UNIQUE (id_prescripcion, hora_programada),
    CONSTRAINT FK_HORARIO_DOSIS_PRESCRIPCION FOREIGN KEY (id_prescripcion)
        REFERENCES PRESCRIPCION (id_prescripcion)
);
GO

CREATE TABLE DOSIS_PROGRAMADA
(
    id_dosis_programada     INT IDENTITY(1,1) NOT NULL,
    id_horario              INT NOT NULL,
    fecha_hora_programada   DATETIME2(0) NOT NULL,
    estado_dosis_programada VARCHAR(20) NOT NULL
        CONSTRAINT DF_DOSIS_PROGRAMADA_estado DEFAULT ('PENDIENTE'),

    CONSTRAINT PK_DOSIS_PROGRAMADA PRIMARY KEY (id_dosis_programada),
    CONSTRAINT UQ_DOSIS_PROGRAMADA_horario_fecha
        UNIQUE (id_horario, fecha_hora_programada),
    CONSTRAINT CK_DOSIS_PROGRAMADA_estado CHECK
        (estado_dosis_programada IN ('PENDIENTE', 'CUMPLIDA', 'OMITIDA')),
    CONSTRAINT FK_DOSIS_PROGRAMADA_HORARIO FOREIGN KEY (id_horario)
        REFERENCES HORARIO_DOSIS (id_horario)
);
GO

CREATE TABLE REGISTRO_TOMA
(
    id_registro          INT IDENTITY(1,1) NOT NULL,
    id_dosis_programada  INT NOT NULL,
    fecha_hora_registro  DATETIME2(0) NOT NULL,
    observacion          VARCHAR(500) NULL,

    CONSTRAINT PK_REGISTRO_TOMA PRIMARY KEY (id_registro),
    CONSTRAINT UQ_REGISTRO_TOMA_id_dosis UNIQUE (id_dosis_programada),
    CONSTRAINT FK_REGISTRO_TOMA_DOSIS FOREIGN KEY (id_dosis_programada)
        REFERENCES DOSIS_PROGRAMADA (id_dosis_programada)
);
GO

CREATE TABLE RECORDATORIO
(
    id_recordatorio      INT IDENTITY(1,1) NOT NULL,
    id_dosis_programada  INT NOT NULL,
    canal                VARCHAR(20) NOT NULL,
    fecha_hora_envio     DATETIME2(0) NULL,
    estado_recordatorio  VARCHAR(20) NOT NULL
        CONSTRAINT DF_RECORDATORIO_estado DEFAULT ('PENDIENTE'),

    CONSTRAINT PK_RECORDATORIO PRIMARY KEY (id_recordatorio),
    CONSTRAINT CK_RECORDATORIO_canal CHECK
        (canal IN ('APP', 'CORREO', 'SMS')),
    CONSTRAINT CK_RECORDATORIO_estado CHECK
        (estado_recordatorio IN ('PENDIENTE', 'ENVIADO', 'FALLIDO')),
    CONSTRAINT FK_RECORDATORIO_DOSIS FOREIGN KEY (id_dosis_programada)
        REFERENCES DOSIS_PROGRAMADA (id_dosis_programada)
);
GO