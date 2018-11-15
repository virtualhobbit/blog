# Author:	@virtualhobbit
# Website:	http://virtualhobbit.com
# Ref:		http://virtualhobbit.com/2015/10/22/wednesday-tidbit-create-an-alert-for-esxi-host-profile-deviation/

# Variables

$vc = "vcsa.lab.mdb-lab.com"
$credential = Get-Credential
$mailto = "virtualhobbit@mdb-lab.com"

# Connect to vCenter
Connect-VIServer $vc -credential $credential

# Get the Datacenter
$dc = "London"
$entity = Get-Datacenter $dc | Get-View

# Create the alarmspec object
$spec = New-Object VMware.Vim.AlarmSpec
$spec.name = "Host profile deviation"
$spec.description = "Monitors host profile deviation"
$spec.enabled = $true

# Expression 1 - Host profile is non-compliant
$spec.expression = New-Object VMware.Vim.OrAlarmExpression
$spec.expression.expression = New-Object VMware.Vim.AlarmExpression[] (1)
$spec.expression.expression[0] = New-Object VMware.Vim.EventAlarmExpression
$spec.expression.expression[0].eventType = "HostNonCompliantEvent"
$spec.expression.expression[0].objectType = "HostSystem"
$spec.expression.expression[0].status = "red"

# Create the alarm action
$spec.action = New-Object VMware.Vim.GroupAlarmAction
$spec.action.action = New-Object VMware.Vim.AlarmAction[] (1)
$spec.action.action[0] = New-Object VMware.Vim.AlarmTriggeringAction
$spec.action.action[0].action = New-Object VMware.Vim.SendEmailAction
$spec.action.action[0].action.toList = $mailto
$spec.action.action[0].action.ccList = ""
$spec.action.action[0].action.subject = "Host non-compliant with profile"
$spec.action.action[0].action.body = ""
$spec.action.action[0].transitionSpecs = New-Object VMware.Vim.AlarmTriggeringActionTransitionSpec[] (1)
$spec.action.action[0].transitionSpecs[0] = New-Object VMware.Vim.AlarmTriggeringActionTransitionSpec
$spec.action.action[0].transitionSpecs[0].startState = "yellow"
$spec.action.action[0].transitionSpecs[0].finalState = "red"
$spec.action.action[0].transitionSpecs[0].repeats = $false
$spec.action.action[0].green2yellow = $false
$spec.action.action[0].yellow2red = $false
$spec.action.action[0].red2yellow = $false
$spec.action.action[0].yellow2green = $false

$spec.setting = New-Object VMware.Vim.AlarmSetting
$spec.setting.toleranceRange = 0
$spec.setting.reportingFrequency = 0

$_this = Get-View -Id 'AlarmManager-AlarmManager'

# Create alarm
$_this.CreateAlarm($entity.MoRef, $spec)

# Disconnect from vCenter
Disconnect-VIServer $vc -Confirm:$false