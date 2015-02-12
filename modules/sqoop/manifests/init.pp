class sqoop {
  $sqoop_version = "1.99.4"
  $sqoop_platform = "hadoop200"
	$hadoop_version = "2.5.2"
  $sqoop_home = "/opt/sqoop-${sqoop_version}-bin-${sqoop_platform}"
  $sqoop_tarball = "sqoop-${sqoop_version}-bin-${sqoop_platform}.tar.gz"

  $mysql_connector_jar = "mysql-connector-java-5.1.13-bin.jar"

  exec { "download_sqoop":
    command => "/tmp/grrr /sqoop/${sqoop_version}/$sqoop_tarball -O /vagrant/$sqoop_tarball --read-timeout=5 --tries=0",
    timeout => 1800,
    path => $path,
    creates => "/vagrant/$sqoop_tarball",
    require => [ Package["openjdk-7-jdk"], Exec["download_grrr"]]
  }

  exec { "unpack_sqoop" :
    command => "tar xf /vagrant/${sqoop_tarball} -C /opt",
    path => $path,
    creates => "${sqoop_home}",
    require => Exec["download_sqoop"]
  }
  exec { "change_owner" :
    command => "/bin/chown -R vagrant.vagrant ${sqoop_home}",
		require => Exec["unpack_sqoop"]
	}

	exec { "remove_old_config" :
		command => "/bin/rm -f ${sqoop_home}/server/conf/catalina.properties ${sqoop_home}/server/conf/sqoop.properties",
		require => Exec["change_owner"]
	}

	file { "${sqoop_home}/server/conf/catalina.properties":
		content => template("sqoop/catalina.properties.erb"),
		owner => vagrant,
		group => vagrant,
    require => Exec["remove_old_config"]
	}

	file { "${sqoop_home}/server/conf/sqoop.properties":
		content => template("sqoop/sqoop.properties.erb"),
		owner => vagrant,
		group => vagrant,
    require => Exec["remove_old_config"]
	}

	file { "${sqoop_home}/lib/":
			ensure => "directory",
			require => Exec["change_owner"]
	} 

	file { "${sqoop_home}/lib/mysql-connector-java.jar":
			source => "puppet:///modules/sqoop/mysql-connector-java.jar",
			ensure => file,
			mode => 644,
			owner => vagrant,
			group => vagrant,
			require => File["${sqoop_home}/lib"]
	}
	
	file { "/etc/profile.d/sqoop-path.sh":
    content => template("sqoop/sqoop-path.sh.erb"),
    owner => root,
    group => root,
  }

}
