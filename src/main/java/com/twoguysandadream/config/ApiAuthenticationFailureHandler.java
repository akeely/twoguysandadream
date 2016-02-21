package com.twoguysandadream.config;


import com.twoguysandadream.resources.ApiConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationFailureHandler;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class ApiAuthenticationFailureHandler implements AuthenticationFailureHandler {

    private static final Logger LOG = LoggerFactory.getLogger(ApiAuthenticationFailureHandler.class);

    private final AuthenticationFailureHandler apiHandler = new SimpleUrlAuthenticationFailureHandler();
    private final AuthenticationFailureHandler webHandler =
        new SimpleUrlAuthenticationFailureHandler(SecurityConfig.LOGIN_PAGE);

    @Override
    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response,
        AuthenticationException exception) throws IOException, ServletException {

        LOG.warn("Authentication failed for {}", request.getRequestURI());
        if (request.getRequestURI().startsWith(ApiConfiguration.ROOT_PATH)) {
            apiHandler.onAuthenticationFailure(request, response, exception);
        } else {
            webHandler.onAuthenticationFailure(request, response, exception);
        }
    }
}
