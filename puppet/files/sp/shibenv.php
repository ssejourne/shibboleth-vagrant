<?php
echo '<table>';
foreach ($_SERVER as $key => $value)
{
        $fkey='_'.$key;
#        if ( strpos($fkey,'SHIB')>1 && $key!="HTTP_SHIB_ATTRIBUTES")
#       if ( strpos($fkey,'SHIB')>1 )
#        {
                echo '<tr>';
                echo '<td>'.$key.'</td><td>'.$value.'</td>';
                echo '</tr>';
#        }
}
echo '<tr><td>(REMOTE_USER)</td><td>'.$_SERVER['REMOTE_USER'].'</td></tr>';
echo '<tr><td>(HTTP_REMOTE_USER)</td><td>'.$_SERVER['HTTP_REMOTE_USER'].'</td></tr>';
echo '<tr><td>HTTP_SHIB_LOGOUTURL</td><td>'.$_SERVER['HTTP_SHIB_LOGOUTURL']
.'<a href="/Shibboleth.sso/Logout?return='.$_SERVER['HTTP_SHIB_LOGOUTURL'].
'%3Freturn">[logout]</a> </td></tr>';
echo '</table>';
echo '<P>';
phpinfo();
?>
