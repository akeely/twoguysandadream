package com.twoguysandadream.config;


import javax.sql.DataSource;

import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.resources.ApiConfiguration;
import com.twoguysandadream.security.DbUserDetailsService;
import com.twoguysandadream.security.OpenIdUserDetailsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.security.web.authentication.ExceptionMappingAuthenticationFailureHandler;

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    static final String LOGIN_PAGE = "/login";

    @Autowired
    private DbUserDetailsService userDetailsService;

    @Override
    protected void configure(HttpSecurity http) throws Exception {

        http
            //.csrf().disable()
            .logout()
                .logoutUrl("/logout")
                .logoutSuccessUrl(LOGIN_PAGE)
                .invalidateHttpSession(true)
                .and()
            .authorizeRequests()
                .antMatchers("/css/**").permitAll()
                .antMatchers("/img/**").permitAll()
                .antMatchers("/js/**").permitAll()
                .anyRequest().authenticated()
                .and()
            .formLogin()
                .loginPage(LOGIN_PAGE)
                .defaultSuccessUrl("/")
                .failureUrl(LOGIN_PAGE + "?error")
                .permitAll();
    }



    @Bean
    public AuthenticationFailureHandler failureHandler() {

        ExceptionMappingAuthenticationFailureHandler handler = new ExceptionMappingAuthenticationFailureHandler();
        handler.setExceptionMappings(ImmutableMap.of(UsernameNotFoundException.class.getName(), "/registration"));
        return handler;
    }


//    @Autowired
//    private DataSource dataSource;

//    @Autowired
//    public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
//        // ensure the passwords are encoded properly
//        User.UserBuilder users = User.withDefaultPasswordEncoder();
//        auth
//                .jdbcAuthentication()
//                .dataSource(dataSource);
//    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Override
    protected void configure(final AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
                .withUser("user1").password(passwordEncoder().encode("user1Pass")).roles("USER")
                .and()
                .withUser("user2").password(passwordEncoder().encode("user2Pass")).roles("USER")
                .and()
                .withUser("admin").password(passwordEncoder().encode("adminPass")).roles("ADMIN");
    }
}
