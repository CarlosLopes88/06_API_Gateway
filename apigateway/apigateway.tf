# API Gateway
resource "aws_api_gateway_rest_api" "concessionaria_api" {
  name        = "concessionaria-api"
  description = "API Gateway para Sistema de Concessionária de Veículos"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Authorizer do Cognito
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  provider_arns = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# Recursos e métodos para /webhook
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "webhook"
}

# Recurso para /webhook/pagseguro
resource "aws_api_gateway_resource" "webhook_pagseguro" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.webhook.id
  path_part   = "pagseguro"
}

# POST /webhook/pagseguro (sem autenticação)
resource "aws_api_gateway_method" "webhook_pagseguro_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.webhook_pagseguro.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook_pagseguro_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.webhook_pagseguro.id
  http_method = aws_api_gateway_method.webhook_pagseguro_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_venda_url}/api/webhook/pagseguro"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Novo endpoint para simulação de pagamento
resource "aws_api_gateway_resource" "webhook_simulacao" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.webhook.id
  path_part   = "simulacao"
}

resource "aws_api_gateway_resource" "webhook_simulacao_pedidoid" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.webhook_simulacao.id
  path_part   = "{pedidoId}"
}

resource "aws_api_gateway_resource" "webhook_simulacao_status" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.webhook_simulacao_pedidoid.id
  path_part   = "{status}"
}

resource "aws_api_gateway_method" "webhook_simulacao_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.webhook_simulacao_status.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true,
    "method.request.path.status"   = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "webhook_simulacao_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.webhook_simulacao_status.id
  http_method = aws_api_gateway_method.webhook_simulacao_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_venda_url}/api/webhook/simulacao/{pedidoId}/{status}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId",
    "integration.request.path.status"   = "method.request.path.status",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /pagamento
resource "aws_api_gateway_resource" "pagamento" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "pagamento"
}

# Recurso para /pagamento/{pedidoId}
resource "aws_api_gateway_resource" "pagamento_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pagamento.id
  path_part   = "{pedidoId}"
}

# POST /pagamento/{pedidoId}
resource "aws_api_gateway_method" "pagamento_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pagamento_id.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pagamento_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pagamento_id.id
  http_method = aws_api_gateway_method.pagamento_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_venda_url}/api/pagamento/{pedidoId}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /pagamento/{pedidoId}
resource "aws_api_gateway_method" "pagamento_get" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pagamento_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pagamento_get" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pagamento_id.id
  http_method = aws_api_gateway_method.pagamento_get.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pagamento/{pedidoId}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /cliente
resource "aws_api_gateway_resource" "cliente" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "cliente"
}

# GET /cliente (listar todos)
resource "aws_api_gateway_method" "cliente_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "cliente_get_all" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
  
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# POST /cliente (criar)
resource "aws_api_gateway_method" "cliente_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "cliente_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
  
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# Configuração de OPTIONS para cliente (CORS)
resource "aws_api_gateway_method" "cliente_options" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cliente_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cliente_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.cliente_options]
}

resource "aws_api_gateway_integration_response" "cliente_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_options.http_method
  status_code = aws_api_gateway_method_response.cliente_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.cliente_options,
    aws_api_gateway_integration.cliente_options
  ]
}

# Recurso para /cliente/{clienteId}
resource "aws_api_gateway_resource" "cliente_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.cliente.id
  path_part   = "{clienteId}"
}

# GET /cliente/{clienteId}
resource "aws_api_gateway_method" "cliente_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.cliente_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.clienteId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "cliente_get_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.cliente_id.id
  http_method = aws_api_gateway_method.cliente_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente/{clienteId}"

  request_parameters = {
    "integration.request.path.clienteId" = "method.request.path.clienteId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /pedido
resource "aws_api_gateway_resource" "pedido" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "pedido"
}

# Configuração de OPTIONS para pedido (CORS)
resource "aws_api_gateway_method" "pedido_options" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pedido_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "pedido_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.pedido_options]
}

resource "aws_api_gateway_integration_response" "pedido_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_options.http_method
  status_code = aws_api_gateway_method_response.pedido_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.pedido_options,
    aws_api_gateway_integration.pedido_options
  ]
}

# GET /pedido (listar todos)
resource "aws_api_gateway_method" "pedido_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_all" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"

  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# GET /pedido/ativos
resource "aws_api_gateway_resource" "pedido_ativos" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "ativos"
}

# Configuração de OPTIONS para pedido/ativos (CORS)
resource "aws_api_gateway_method" "pedido_ativos_options" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_ativos.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pedido_ativos_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_ativos.id
  http_method = aws_api_gateway_method.pedido_ativos_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "pedido_ativos_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_ativos.id
  http_method = aws_api_gateway_method.pedido_ativos_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.pedido_ativos_options]
}

resource "aws_api_gateway_integration_response" "pedido_ativos_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_ativos.id
  http_method = aws_api_gateway_method.pedido_ativos_options.http_method
  status_code = aws_api_gateway_method_response.pedido_ativos_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.pedido_ativos_options,
    aws_api_gateway_integration.pedido_ativos_options
  ]
}

resource "aws_api_gateway_method" "pedido_get_ativos" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_ativos.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_ativos" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_ativos.id
  http_method = aws_api_gateway_method.pedido_get_ativos.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido/ativos"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
  
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# GET /pedido/status/{status}
resource "aws_api_gateway_resource" "pedido_status" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "pedido_status_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido_status.id
  path_part   = "{status}"
}

resource "aws_api_gateway_method" "pedido_get_status" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_status_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.status" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_status" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_status_value.id
  http_method = aws_api_gateway_method.pedido_get_status.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido/status/{status}"

  request_parameters = {
    "integration.request.path.status" = "method.request.path.status",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /pedido/cliente/{clienteId}
resource "aws_api_gateway_resource" "pedido_cliente" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "cliente"
}

resource "aws_api_gateway_resource" "pedido_cliente_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido_cliente.id
  path_part   = "{clienteId}"
}

resource "aws_api_gateway_method" "pedido_get_cliente" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_cliente_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.clienteId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_cliente" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_cliente_id.id
  http_method = aws_api_gateway_method.pedido_get_cliente.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido/cliente/{clienteId}"

  request_parameters = {
    "integration.request.path.clienteId" = "method.request.path.clienteId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# POST /pedido (criar)
resource "aws_api_gateway_method" "pedido_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.header.Authorization" = true,
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "pedido_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_venda_url}/api/pedido"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"

  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization",
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

# Recurso para /pedido/{pedidoId}
resource "aws_api_gateway_resource" "pedido_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "{pedidoId}"
}

# GET /pedido/{pedidoId}
resource "aws_api_gateway_method" "pedido_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_id.id
  http_method = aws_api_gateway_method.pedido_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido/{pedidoId}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# PUT /pedido/{pedidoId}/status
resource "aws_api_gateway_resource" "pedido_id_status" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.pedido_id.id
  path_part   = "status"
}

resource "aws_api_gateway_method" "pedido_put_status" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_id_status.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true,
    "method.request.header.Authorization" = true,
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "pedido_put_status" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_id_status.id
  http_method = aws_api_gateway_method.pedido_put_status.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "PUT"
  uri                    = "http://${var.lb_venda_url}/api/pedido/{pedidoId}/status"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization",
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Endpoint de teste para pedidos sem autenticação
resource "aws_api_gateway_resource" "test_pedido" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "test-pedido"
}

resource "aws_api_gateway_method" "test_pedido" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.test_pedido.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_pedido" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.test_pedido.id
  http_method = aws_api_gateway_method.test_pedido.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/api/pedido"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Rota de teste para verificação de saúde do serviço de pedidos
resource "aws_api_gateway_resource" "pedido_health" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "pedido-health"
}

resource "aws_api_gateway_method" "pedido_health" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.pedido_health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pedido_health" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.pedido_health.id
  http_method = aws_api_gateway_method.pedido_health.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_venda_url}/health"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /produto (veículos)
resource "aws_api_gateway_resource" "produto" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "produto"
}

# GET /produto (listar todos)
resource "aws_api_gateway_method" "produto_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_all" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
  
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# POST /produto (criar)
resource "aws_api_gateway_method" "produto_post" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  
  request_parameters = {
    "method.request.header.Authorization" = true,
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "produto_post" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_produto_url}/api/produto"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
  
  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization",
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
}

# Configuração de OPTIONS para produto (CORS)
resource "aws_api_gateway_method" "produto_options" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "produto_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "produto_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.produto_options]
}

resource "aws_api_gateway_integration_response" "produto_options" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_options.http_method
  status_code = aws_api_gateway_method_response.produto_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.produto_options,
    aws_api_gateway_integration.produto_options
  ]
}

# Recurso para /produto/{produtoId}
resource "aws_api_gateway_resource" "produto_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "{produtoId}"
}

# GET /produto/{produtoId}
resource "aws_api_gateway_method" "produto_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_id" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# PUT /produto/{produtoId}
resource "aws_api_gateway_method" "produto_put" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true,
    "method.request.header.Authorization" = true,
    "method.request.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration" "produto_put" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_put.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "PUT"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization",
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# DELETE /produto/{produtoId}
resource "aws_api_gateway_method" "produto_delete" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_delete" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_delete.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "DELETE"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Rotas específicas para veículos
# GET /produto/marca/{marca}
resource "aws_api_gateway_resource" "produto_marca" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "marca"
}

resource "aws_api_gateway_resource" "produto_marca_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto_marca.id
  path_part   = "{marca}"
}

resource "aws_api_gateway_method" "produto_get_marca" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_marca_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.marca" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_marca" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_marca_value.id
  http_method = aws_api_gateway_method.produto_get_marca.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/marca/{marca}"

  request_parameters = {
    "integration.request.path.marca" = "method.request.path.marca",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /produto/modelo/{modelo}
resource "aws_api_gateway_resource" "produto_modelo" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "modelo"
}

resource "aws_api_gateway_resource" "produto_modelo_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto_modelo.id
  path_part   = "{modelo}"
}

resource "aws_api_gateway_method" "produto_get_modelo" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_modelo_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.modelo" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_modelo" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_modelo_value.id
  http_method = aws_api_gateway_method.produto_get_modelo.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/modelo/{modelo}"

  request_parameters = {
    "integration.request.path.modelo" = "method.request.path.modelo",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /produto/ano/{ano}
resource "aws_api_gateway_resource" "produto_ano" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "ano"
}

resource "aws_api_gateway_resource" "produto_ano_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto_ano.id
  path_part   = "{ano}"
}

resource "aws_api_gateway_method" "produto_get_ano" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_ano_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.ano" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_ano" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_ano_value.id
  http_method = aws_api_gateway_method.produto_get_ano.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/ano/{ano}"

  request_parameters = {
    "integration.request.path.ano" = "method.request.path.ano",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /produto/placa/{placa}
resource "aws_api_gateway_resource" "produto_placa" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "placa"
}

resource "aws_api_gateway_resource" "produto_placa_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto_placa.id
  path_part   = "{placa}"
}

resource "aws_api_gateway_method" "produto_get_placa" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_placa_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.placa" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_placa" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_placa_value.id
  http_method = aws_api_gateway_method.produto_get_placa.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/placa/{placa}"

  request_parameters = {
    "integration.request.path.placa" = "method.request.path.placa",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /produto/cor/{cor}
resource "aws_api_gateway_resource" "produto_cor" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "cor"
}

resource "aws_api_gateway_resource" "produto_cor_value" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_resource.produto_cor.id
  path_part   = "{cor}"
}

resource "aws_api_gateway_method" "produto_get_cor" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.produto_cor_value.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.cor" = true,
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_cor" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.produto_cor_value.id
  http_method = aws_api_gateway_method.produto_get_cor.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/cor/{cor}"

  request_parameters = {
    "integration.request.path.cor" = "method.request.path.cor",
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Rota de teste sem autenticação
resource "aws_api_gateway_resource" "test" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  parent_id   = aws_api_gateway_rest_api.concessionaria_api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test" {
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id   = aws_api_gateway_resource.test.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Deploy da API
resource "aws_api_gateway_deployment" "concessionaria" {
  rest_api_id = aws_api_gateway_rest_api.concessionaria_api.id
  
  depends_on = [
    aws_api_gateway_integration.webhook_pagseguro_post,
    aws_api_gateway_integration.webhook_simulacao_post,
    aws_api_gateway_integration.pagamento_post,
    aws_api_gateway_integration.pagamento_get,
    aws_api_gateway_integration.cliente_get_all,
    aws_api_gateway_integration.cliente_post,
    aws_api_gateway_integration.cliente_get_id,
    aws_api_gateway_integration.pedido_get_all,
    aws_api_gateway_integration.pedido_get_ativos,
    aws_api_gateway_integration.pedido_get_status,
    aws_api_gateway_integration.pedido_get_cliente,
    aws_api_gateway_integration.pedido_post,
    aws_api_gateway_integration.pedido_get_id,
    aws_api_gateway_integration.pedido_put_status,
    aws_api_gateway_integration.test_pedido,
    aws_api_gateway_integration.pedido_health,
    aws_api_gateway_integration.produto_get_all,
    aws_api_gateway_integration.produto_post,
    aws_api_gateway_integration.produto_get_id,
    aws_api_gateway_integration.produto_put,
    aws_api_gateway_integration.produto_delete,
    aws_api_gateway_integration.produto_get_marca,
    aws_api_gateway_integration.produto_get_modelo,
    aws_api_gateway_integration.produto_get_ano,
    aws_api_gateway_integration.produto_get_placa,
    aws_api_gateway_integration.produto_get_cor,
    aws_api_gateway_integration.cliente_options,
    aws_api_gateway_integration_response.cliente_options,
    aws_api_gateway_integration.produto_options,
    aws_api_gateway_integration_response.produto_options,
    aws_api_gateway_integration.pedido_options,
    aws_api_gateway_integration_response.pedido_options,
    aws_api_gateway_integration.pedido_ativos_options,
    aws_api_gateway_integration_response.pedido_ativos_options
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Estágio da API
resource "aws_api_gateway_stage" "concessionaria" {
  deployment_id = aws_api_gateway_deployment.concessionaria.id
  rest_api_id   = aws_api_gateway_rest_api.concessionaria_api.id
  stage_name    = "v1"
}

variable "cognito_user_pool_arn" {
  description = "ARN do Cognito User Pool (exemplo: arn:aws:cognito-idp:us-east-1:740588470221:userpool/us-east-1_asasasasasa)"
  type        = string
}

variable "lb_venda_url" {
  description = "URL do LoadBalancer do serviço de Venda e Pagamentos"
  type        = string
}

variable "lb_produto_url" {
  description = "URL do LoadBalancer do serviço de Produto (Veículos)"
  type        = string
}

variable "lb_cliente_url" {
  description = "URL do LoadBalancer do serviço de Cliente"
  type        = string
}

# Outputs
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.concessionaria.invoke_url}"
}

output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.concessionaria_api.execution_arn
}