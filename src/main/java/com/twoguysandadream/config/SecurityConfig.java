package com.twoguysandadream.config;


import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.security.DbUserDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.ExceptionMappingAuthenticationFailureHandler;
import org.springframework.web.filter.ForwardedHeaderFilter;

import javax.servlet.DispatcherType;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    public static final PasswordEncoder ENCODER = new BCryptPasswordEncoder();

    static final String LOGIN_PAGE = "/login";

    @Autowired
    private DbUserDetailsService userDetailsService;

    // Configures the ForwardedHeaderFilter so that X-Forwarded-For and related headers are respected. This is needed
    // because the app is running behind an AWS ALB, and otherwise OAuth redirect URLs are not correct.
    @Bean
    public FilterRegistrationBean<ForwardedHeaderFilter> forwardedHeaderFilter() {
        ForwardedHeaderFilter filter = new ForwardedHeaderFilter();
        FilterRegistrationBean<ForwardedHeaderFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setDispatcherTypes(DispatcherType.REQUEST, DispatcherType.ASYNC, DispatcherType.ERROR);
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return registration;
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {

        http
            .logout()
                .logoutUrl("/logout")
                .logoutSuccessUrl(LOGIN_PAGE)
                .invalidateHttpSession(true)
                .and()
            .authorizeRequests()
                .antMatchers("/css/**").permitAll()
                .antMatchers("/img/**").permitAll()
                .antMatchers("/js/**").permitAll()
                .antMatchers("/login").permitAll()
                .anyRequest().authenticated()
                .and()
                .oauth2Login();
    }



    @Bean
    public AuthenticationFailureHandler failureHandler() {

        ExceptionMappingAuthenticationFailureHandler handler = new ExceptionMappingAuthenticationFailureHandler();
        handler.setExceptionMappings(ImmutableMap.of(UsernameNotFoundException.class.getName(), "/registration"));
        return handler;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return ENCODER;
    }

    @Bean
    public AuthenticationProvider authProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(ENCODER);
        return provider;
    }
    
    @Override
    protected void configure(AuthenticationManagerBuilder auth) {
        auth.authenticationProvider(authProvider());
    }
}
