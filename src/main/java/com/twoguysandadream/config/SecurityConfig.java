package com.twoguysandadream.config;


import com.twoguysandadream.resources.ApiConfiguration;
import com.twoguysandadream.security.OpenIdUserDetailsService;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable() // TODO: Figure this out!
            .logout()
                .logoutUrl("/logout")
                .logoutSuccessUrl("/login.html")
                .invalidateHttpSession(true)
                .and()
            .authorizeRequests()
            .antMatchers(ApiConfiguration.ROOT_PATH + "**").authenticated()
            .anyRequest().permitAll()
            .and()
            .openidLogin()
            .loginPage("/login.html")
            .permitAll()
            .authenticationUserDetailsService(new OpenIdUserDetailsService())
            .attributeExchange("https://www.google.com/.*")
            .attribute("email")
            .type("http://axschema.org/contact/email")
            .required(true)
            .and()
            .attribute("firstname")
            .type("http://axschema.org/namePerson/first")
            .required(true)
            .and()
            .attribute("lastname")
            .type("http://axschema.org/namePerson/last")
            .required(true)
            .and()
            .and()
            .attributeExchange(".*yahoo.com.*")
            .attribute("email")
            .type("http://axschema.org/contact/email")
            .required(true)
            .and()
            .attribute("fullname")
            .type("http://axschema.org/namePerson")
            .required(true)
            .and()
            .and()
            .attributeExchange(".*myopenid.com.*")
            .attribute("email")
            .type("http://schema.openid.net/contact/email").required(true).and()
            .attribute("fullname").type("http://schema.openid.net/namePerson")
            .required(true);
    }
}
