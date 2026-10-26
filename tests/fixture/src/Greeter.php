<?php

namespace Fixture;

final class Greeter
{
    public function greet(string $name): string
    {
        if ($name === '') {
            return 'Hello!';
        }

        return "Hello, {$name}!";
    }
}
