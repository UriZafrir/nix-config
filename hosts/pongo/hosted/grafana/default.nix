{ config, ... }:
let
  domain = "monitoring.ilanjoselevich.com";
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://${domain}";
        enable_gzip = true;
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
      };
      auth = {
        disable_login_form = true;
        disable_signout_menu = true;
      };
      "auth.basic".enabled = false;
      "auth.generic_oauth" = {
        enabled = true;
        allow_sign_up = true;
        auto_login = true;
        name = "Kanidm";
        client_id = "grafana";
        client_secret = "$__file{${config.age.secrets.grafana-oauth2.path}}";
        scopes = "openid profile email";
        auth_url = "https://idm.ilanjoselevich.com/ui/oauth2";
        token_url = "https://idm.ilanjoselevich.com/oauth2/token";
        api_url = "https://idm.ilanjoselevich.com/oauth2/openid/grafana/userinfo";
        use_pkce = true;
        login_attribute_path = "preferred_username";
        allow_assign_grafana_admin = true;
        role_attribute_path = "contains(scopes[*], 'admin') && 'GrafanaAdmin'";
      };
      security = {
        secret_key = "$__file{${config.age.secrets.grafana-signing-key.path}}";
        cookie_secure = true;
        disable_gravatar = true;
        disable_initial_admin_creation = true;
      };
      log.mode = "syslog";
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ config.services.grafana.settings.database.name ];
    ensureUsers = [{
      name = config.services.grafana.settings.database.user;
      ensurePermissions."DATABASE ${config.services.grafana.settings.database.name}" = "ALL PRIVILEGES";
    }];
  };

  age.secrets = {
    grafana-oauth2 = {
      rekeyFile = ./grafana-oauth2.age;
      group = "grafana";
      owner = "grafana";
    };
    grafana-signing-key = {
      rekeyFile = ./grafana-signing-key.age;
      group = "grafana";
      owner = "grafana";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs.${domain}.email = "personal@ilanjoselevich.com";
  };
}
