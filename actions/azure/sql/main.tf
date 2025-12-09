resource "azurerm_resource_group" "default" {
  name     = "rg-sql-demo"
  location = var.location
}

resource "random_string" "sql" {
  length  = 12
  special = false
  upper   = false
  numeric = false
}

resource "random_password" "sql" {
  length = 20
}

resource "azurerm_mssql_server" "demo" {
  name                         = "terraformactionsdemo"
  resource_group_name          = azurerm_resource_group.default.name
  location                     = azurerm_resource_group.default.location
  version                      = "12.0"
  administrator_login          = random_string.sql.result
  administrator_login_password = random_password.sql.result
}

resource "azurerm_mssql_database" "demo" {
  name      = "demo"
  server_id = azurerm_mssql_server.demo.id
  sku_name  = "P2"
  collation = "SQL_Latin1_General_CP1_CI_AS"
}

resource "azurerm_mssql_job_agent" "demo" {
  name        = "sqldemoagent"
  location    = azurerm_resource_group.default.location
  database_id = azurerm_mssql_database.demo.id
}

resource "azurerm_mssql_job_credential" "demo" {
  name         = "sqldemocred"
  job_agent_id = azurerm_mssql_job_agent.demo.id
  username     = random_string.sql.result
  password     = random_password.sql.result
}

resource "azurerm_mssql_job_target_group" "demo" {
  name         = "demotargetgroup"
  job_agent_id = azurerm_mssql_job_agent.demo.id

  job_target {
    server_name   = azurerm_mssql_server.demo.name
    database_name = azurerm_mssql_database.demo.name
  }
}

resource "azurerm_mssql_job" "demo" {
  name         = "insertJobLog"
  job_agent_id = azurerm_mssql_job_agent.demo.id
}

resource "azurerm_mssql_job_step" "demo" {
  name                = "insertLogStep"
  job_id              = azurerm_mssql_job.demo.id
  job_credential_id   = azurerm_mssql_job_credential.demo.id
  job_target_group_id = azurerm_mssql_job_target_group.demo.id

  job_step_index = 1
  sql_script     = <<EOT
IF NOT EXISTS (SELECT * FROM sys.objects WHERE [name] = N'Pets')
  CREATE TABLE Pets (
    Animal NVARCHAR(50),
    Name NVARCHAR(50),
    NickName NVARCHAR(50),
  );
EOT

  lifecycle {
    action_trigger {
      events  = [after_create, after_update]
      actions = [action.azurerm_mssql_execute_job.example]
    }
  }
}

# resource "terraform_data" "example" {
#   input = azurerm_mssql_job_step.demo.id

#   lifecycle {
#     action_trigger {
#       events  = [after_create, after_update]
#       actions = [action.azurerm_mssql_execute_job.example]
#     }
#   }
# }

action "azurerm_mssql_execute_job" "example" {
  config {
    job_id              = azurerm_mssql_job.demo.id
    wait_for_completion = false
    timeout             = "15m"
  }
}
