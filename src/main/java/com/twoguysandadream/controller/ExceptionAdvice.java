package com.twoguysandadream.controller;

import com.twoguysandadream.security.NotRegisteredException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.ModelAndView;

@ControllerAdvice
public class ExceptionAdvice {

    @ExceptionHandler(NotRegisteredException.class)
    public ModelAndView notRegistered(NotRegisteredException exception) {

        ModelAndView mov = new ModelAndView("/registration");
        mov.addObject("openIdToken", exception.getToken());

        return mov;
    }
}
