# XAML for the GUI layout
[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Service Monitor" Height="400" Width="600">
    <Grid>
        <TextBox x:Name="OutputBox" Margin="10,10,10,50" VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
        <Button Content="Start Monitoring" Width="150" Height="30" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="10,0,0,10" Name="StartButton"/>
        <Button Content="Stop Monitoring" Width="150" Height="30" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,10,10" Name="StopButton"/>
    </Grid>
</Window>
'@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlLoader]::Load($reader)

# Get controls
$outputBox = $window.FindName("OutputBox")
$startButton = $window.FindName("StartButton")
$stopButton = $window.FindName("StopButton")

# Function to start monitoring services
function Start-Monitoring {
    while ($true) {
        $services = Get-Service | Where-Object { $_.Status -eq "Running" }

        Start-Sleep -Seconds 1

        $newServices = Compare-Object -ReferenceObject $services -DifferenceObject (Get-Service | Where-Object { $_.Status -eq "Running" }) -Property Name

        foreach ($newService in $newServices) {
            $serviceDetails = Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $newService.Name } | Select-Object Name, DisplayName, State, PathName

            [Windows.MessageBox]::Show('!!!!!!!!!! A SERVICE HAS STARTED !!!!!!!!!!`r`n' +
                'Display Name: ' + $serviceDetails.DisplayName + "`r`n" +
                'Name: ' + $serviceDetails.Name + "`r`n" +
                'State: ' + $serviceDetails.State + "`r`n" +
                'Path: ' + $serviceDetails.PathName + "`r`n" +
                '!!!!!!!!!! A SERVICE HAS STARTED !!!!!!!!!!`r`n' +
                'Kill? (y/n)', 'Service Alert', 'YesNo', 'Information')

            $response = Read-Host

            if ($response -eq "Y" -or $response -eq "y") {
                Stop-Service -Name $newService.Name -Force -PassThru | Out-Null
                [Windows.MessageBox]::Show('Kerblam! Service has been eliminated...`r`n' +
                    'Might want to search for some bad guys around here`r`n', 'Service Alert', 'OK', 'Information')
            } elseif ($response -eq "N" -or $response -eq "n") {
                [Windows.MessageBox]::Show('Letting that service slide...for now...`r`n', 'Service Alert', 'OK', 'Information')
            }
        }
    }
}

# Event handler for Start button
$startButton.Add_Click({
    Start-Monitoring
})

# Event handler for Stop button
$stopButton.Add_Click({
    Stop-Process -Name "powershell" -Force
})

# Show the window
[Windows.Markup.ComponentDispatcher]::Run()

