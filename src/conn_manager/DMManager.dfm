object ConnManager: TConnManager
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 287
  Width = 511
  object FDManager: TFDManager
    FormatOptions.AssignedValues = [fvMapRules]
    FormatOptions.OwnMapRules = True
    FormatOptions.MapRules = <>
    Left = 24
    Top = 16
  end
  object WaitCursor: TFDGUIxWaitCursor
    Provider = 'FMX'
    Left = 24
    Top = 64
  end
  object RemoteLog: TFDMoniRemoteClientLink
    Left = 24
    Top = 112
  end
  object FileLog: TFDMoniFlatFileClientLink
    Left = 24
    Top = 160
  end
  object SybaseLink: TFDPhysASADriverLink
    Left = 400
    Top = 16
  end
  object PostgreLink: TFDPhysPgDriverLink
    Left = 400
    Top = 64
  end
  object MySQLLink: TFDPhysMySQLDriverLink
    Left = 400
    Top = 112
  end
  object ODBCLink: TFDPhysODBCDriverLink
    Left = 400
    Top = 168
  end
  object SQLLiteLink: TFDPhysSQLiteDriverLink
    Left = 400
    Top = 224
  end
  object FirebirdLink: TFDPhysFBDriverLink
    Left = 344
    Top = 16
  end
end
