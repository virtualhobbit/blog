# Variables

$vc = "vcsa.lab.mdb-lab.com"
$credential = Get-Credential
$mailto = "virtualhobbit@mdb-lab.com"

# Connect to vCenter
Connect-VIServer $vc -credential $credential

$alarmMgr = Get-View AlarmManager
$dc = "London"
$entity = Get-Datacenter $dc | Get-View

# Create AlarmSpec object
$alarm = New-Object VMware.Vim.AlarmSpec
$alarm.Name = "Host Profile violation"
$alarm.Description = "Monitors host profile deviation"
$alarm.Enabled = $TRUE
 
# Alarm action 
$alarm.action = New-Object VMware.Vim.GroupAlarmAction
$trigger1 = New-Object VMware.Vim.AlarmTriggeringAction
$trigger1.action = New-Object VMware.Vim.SendEmailAction
$trigger1.action.ToList = $mailTo
$trigger1.action.Subject = "Host non-compliant with profile"
$trigger1.Action.CcList = ""
$trigger1.Action.Body = "" 
  
# Transition 1a - yellow --> red
$trans1a = New-Object VMware.Vim.AlarmTriggeringActionTransitionSpec
$trans1a.StartState = "yellow"
$trans1a.FinalState = "red"
 
# Transition 1b - red --> yellow
$trans1b = New-Object VMware.Vim.AlarmTriggeringActionTransitionSpec
$trans1b.StartState = "red"
$trans1b.FinalState = "yellow"
 
$trigger1.TransitionSpecs += $trans1a
$trigger1.TransitionSpecs += $trans1b
 
$alarm.action.action += $trigger1
 
# Expression 1 - Host profile compliant
$expression1 = New-Object VMware.Vim.EventAlarmExpression
$expression1.EventType = $null
$expression1.eventTypeId = "Host compliant with profile"
$expression1.objectType = "HostSystem"
$expression1.status = "yellow"
 
# Expression 2 - Host profile non-compliant
$expression2 = New-Object VMware.Vim.EventAlarmExpression
$expression2.EventType = $null
$expression2.eventTypeId = "Host compliant with profile"
$expression2.objectType = "HostSystem"
$expression2.status = "red"
 
$alarm.expression = New-Object VMware.Vim.OrAlarmExpression
$alarm.expression.expression += $expression1
$alarm.expression.expression += $expression2
 
$alarm.setting = New-Object VMware.Vim.AlarmSetting
$alarm.setting.reportingFrequency = 0
$alarm.setting.toleranceRange = 0
 
# Create alarm.
$alarmMgr.CreateAlarm($entity.MoRef, $alarm)

# Disconnect from vCenter
Disconnect-VIServer $vc -Confirm:$false