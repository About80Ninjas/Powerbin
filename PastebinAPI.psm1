if(Test-Path -Path $env:USERPROFILE\Documents\pastebinAPI.json)
{
  $Script:Settings = Get-Content -Path .\Documents\pastebinAPI.json |ConvertFrom-Json
}
else
{
  $Script:Settings = @{
    ApiKey      = Read-Host -Prompt 'Enter API key'
    ApiUserName = Read-Host -Prompt 'Enter API user name'
  }
}
function Convert-UnixTime 
{
  <#
      .SYNOPSIS
      Describe purpose of "Convert-UnixTime" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER Date
      Describe parameter -Date.

      .EXAMPLE
      Convert-UnixTime -Date Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Convert-UnixTime

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param
  (
    [String]
    [Parameter(Mandatory,HelpMessage = 'Unix date')]
    $Date
  )
  
  $ConvertedTime = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Date))
  
  Write-Output -InputObject $ConvertedTime
}


function Rename-Title{

  param
  (
    [String]
    [Parameter(Mandatory)]
    $Title
  )


}

function Get-TrendingPaste
{
  <#
      .SYNOPSIS
      Describe purpose of "Get-TrendingPast" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .EXAMPLE
      Get-TrendingPast
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-TrendingPast

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  $url = 'http://pastebin.com/api/api_post.php'
  $Body = @{
    api_dev_key = $Script:Settings.ApiKey
    api_option  = 'trends'
  }
 
  
  $template = @'
<paste>
<paste_key>{Key*:Dmfi0VCq}</paste_key>
<paste_date>{Date:1470724356}</paste_date>
<paste_title>{Title:PokÃ©mon Shuffle update 1.3.17}</paste_title>
<paste_size>{Size:22205}</paste_size>
<paste_expire_date>{Expire:0}</paste_expire_date>
<paste_private>{Private:0}</paste_private>
<paste_format_short>text</paste_format_short>
<paste_format_long>{Format:None}</paste_format_long>
<paste_url>{url:http://pastebin.com/Dmfi0VCq}</paste_url>
<paste_hits>{Hits:2603}</paste_hits>
</paste>
<paste>
<paste_key>{Key*:HujkewEu}</paste_key>
<paste_date>{Date:1470933441}</paste_date>
<paste_title>{Title:DS}</paste_title>
<paste_size>{Size:31081}</paste_size>
<paste_expire_date>{Expire:0}</paste_expire_date>
<paste_private>{Private:0}</paste_private>
<paste_format_short>text</paste_format_short>
<paste_format_long>{Format:None}</paste_format_long>
<paste_url>{url:http://pastebin.com/HujkewEu}</paste_url>
<paste_hits>{Hits:770}</paste_hits>
</paste>
<paste>
<paste_key>{Key*:t9G2mwph}</paste_key>
<paste_date>{Date:1470862219}</paste_date>
<paste_title>{Title:miracho_config3}</paste_title>
<paste_size>{Size:8538}</paste_size>
<paste_expire_date>{Expire:0}</paste_expire_date>
<paste_private>{Private:0}</paste_private>
<paste_format_short>json</paste_format_short>
<paste_format_long>{Format:JSON}</paste_format_long>
<paste_url>{url:http://pastebin.com/t9G2mwph}</paste_url>
<paste_hits>{Hits:5151}</paste_hits>
</paste>
'@

  $Return = Invoke-RestMethod -Uri $url -Body $Body -Method Post | ConvertFrom-String -TemplateContent $template -ErrorAction Stop
  
  foreach($Paste in $Return)
  {
    $Property = [Ordered]@{
      Title  = if($Paste.Title -eq '')
      {
        'NOT PROVIDED'
      }
      else
      {
        ($Paste.Title).replace('&quot;',$([char]34))
      }
      URL    = $Paste.url
      Format = $Paste.Format
      Date   = if($Paste.Date.Length -ne 10)
      {
        'NOT PROVIDED'
      }else
      {
        Convert-UnixTime -Date $Paste.Date
      }
      Size   = "$($Paste.Size)kb"
      Expire = if( $Paste.Expire -eq 0)
      {
        'No'
      }else
      {
        Convert-UnixTime -Date $Paste.Expire
      }
    }
    
    $Obj = New-Object -TypeName PSObject -Property $Property
    $Obj.psobject.TypeNames.Insert(0, 'About80Ninjas.Pastebin.Trending')
    
    Write-Output -InputObject $Obj
  }
}


function Save-Paste {
   [CmdletBinding(DefaultParameterSetName='Key')]
  param
  (
    [String]
    [Parameter(Mandatory,ParameterSetName='Key')]
    $Key,
  
    [String]
    [Parameter(Mandatory,ParameterSetName='url')]
    $url,
    
    [String]
    [Parameter(Mandatory,ParameterSetName='url')]
    [Parameter(Mandatory,ParameterSetName='Key')]
    [Alias("Title")]
    $FileName,
    
    [String]
    [Parameter(Mandatory,ParameterSetName='url')]
    [Parameter(Mandatory,ParameterSetName='Key')]
    $Format,
    
    [String]
    [Parameter(ParameterSetName='url')]
    [Parameter(ParameterSetName='Key')]
    $FilePath =  "$env:USERPROFILE\Downloads"
  )
  
  $pattern = "[{0}]" -f ([Regex]::Escape( [System.IO.Path]::GetInvalidFileNameChars() -join '' ))
  
  if($FileName -match $pattern){
    #TODO: Make name file safe
    #$FileName = 'Safe file name'
    throw 'Safe file name not implemented yet'
  }
  
  if($PSCmdlet.ParameterSetName -eq 'Key'){
    $NewUrl = 'https://pastebin.com/raw/{0}' -f $Key
  }else{
    #TODO: Add raw to url if not present
    throw 'url not implemented yet'
  }
  
  $FileExt = switch($Format.ToLower(){
    #TODO: Add fileformats
    'none' {'.txt'}
    'json' {'.json'}
    default {'.txt'}
  }
  
  try{
    $Return = Invoke-RestMethod -Uri $NewUrl -ErrorAction Stop
    New-Item -Path $FilePath -Name ($FileName + $FileExt) -Value $Return -ItemType File
  }catch{
    #TODO:Make proper error
    throw 'Unabel to get paste'
  }
}


Export-ModuleMember -Function Get-TrendingPaste,Save-Paste