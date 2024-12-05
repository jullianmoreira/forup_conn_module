object ConnManager: TConnManager
  OnCreate = DataModuleCreate
  Height = 359
  Width = 639
  PixelsPerInch = 120
  object FDManager: TFDManager
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <>
    Left = 30
    Top = 20
  end
  object WaitCursor: TFDGUIxWaitCursor
    Provider = 'FMX'
    Left = 30
    Top = 80
  end
  object RemoteLog: TFDMoniRemoteClientLink
    Left = 30
    Top = 140
  end
  object FileLog: TFDMoniFlatFileClientLink
    Left = 30
    Top = 200
  end
  object SybaseLink: TFDPhysASADriverLink
    Left = 500
    Top = 20
  end
  object PostgreLink: TFDPhysPgDriverLink
    Left = 500
    Top = 80
  end
  object MySQLLink: TFDPhysMySQLDriverLink
    Left = 500
    Top = 140
  end
  object ODBCLink: TFDPhysODBCDriverLink
    Left = 500
    Top = 210
  end
  object SQLLiteLink: TFDPhysSQLiteDriverLink
    Left = 500
    Top = 280
  end
  object FirebirdLink: TFDPhysFBDriverLink
    Left = 430
    Top = 20
  end
end
