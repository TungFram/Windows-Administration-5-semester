$ServersData_Json = @{
    FirstServer=@{
        LocalNetworkAddress = "10.0.0.7";
        Ipv4Address         = "169.254.5.44";
        Mask                = "255.0.0.0"
    };

    SecondServer=@{
        LocalNetworkAddress = "10.0.0.2"; 
        Ipv4Address         = "10.0.0.2"; 
        Mask                = "255.0.0.0"
    }
}

$ScopeData_Json = @{
    CommonInfo = @{
        ScopeID         = "10.0.0.0";
        Name            = "Lab4Part5Scope 10.0.0.100-200";
        Description     = "Scope 10.0.0.100-200 created by script on lab 4."
        LeaseDuration   = "00:01:00"
        State           = "InActive";
    };

    RangeInfo = @{
        StartRange  = "10.0.0.100";
        EndRange    = "10.0.0.200";
        SubnetMask  = "255.0.0.0";
    };

    ExclusionInfo = @{
        StartRange  = "10.0.0.195";
        EndRange    = "10.0.0.200";
    };

    ServersInfo = @{
        DnsAddress      = "10.0.0.7";
        RouterAddress   = "10.0.0.7";
    };

    ReservationInfo = @{
        MACAdress         = "00-01-02-03-04-05";
        ReservedIPAdress  = "10.0.0.199";
        Description       = "Reservation to 10.0.0.199 for MAC 00-01-02-03-04-05";
    };

    PolicyInfo = @{
        Name = "Policy for router via script51";
        Description = "lab 4. DHCP scope level policy for MAC addresses AA-01-02* where router is 10.10.10.10";
        Condition = "OR";
        MacAdresses = @{
            AA_01_02_any = "AA-01-02*";
        };
        StartRange  = "10.0.0.100";
        EndRange    = "10.0.0.195";
        FeatureInfo = @{
            Router = @{
                Address = "10.10.10.10";
                OptionID = "3";
            };
        };
    };

    FailoverInfo = @{
        Name = "";
        ComputerName = "";
        PartnerServer = "";
        MaxClientLeadTime = "00:30:00";
        StateSwitchInterval = "00:00:01";
        AutoStateTransition = $True;
        ReservePercent = "35"
        SharedSecret = "123"
    };
}

$ScopeData_Json | ConvertTo-Json | Out-File "C:\Users\Администратор\Desktop\Scripts\Lab4\ScopeData_Json.json"

$ServersData_Json | ConvertTo-Json | Out-File "C:\Users\Администратор\Desktop\Scripts\Lab4\ServersData_Json.json"