<?php
/**
 * Copyright © 2016 Magento. All rights reserved.
 * See COPYING.txt for license details.
 */
namespace MagentoDevBox\Command;

require_once __DIR__ . '/../AbstractCommand.php';

use MagentoDevBox\AbstractCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

/**
 * Command for Magento installation
 */
class MagentoSetup extends AbstractCommand
{
    /**
     * {@inheritdoc}
     */
    protected function configure()
    {
        $this->setName('magento:setup')
            ->setDescription('Install Magento')
            ->setHelp('This command allows you to install Magento.');

        parent::configure();
    }

    private function cleanupSystem()
    {
        $this->executeCommands('cd /var/www/magento2 && rm -rf var/* pub/static/* app/etc/env.php app/etc/config.php');
    }

    /**
     * {@inheritdoc}
     */
    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $this->cleanupSystem();

        $command = sprintf(
            'cd /var/www/magento2 && php bin/magento setup:install'
                . ' --base-url=http://localhost:1748/ --db-host=db --db-name=magento2'
                . ' --db-user=root --db-password=root --admin-firstname=Magento --admin-lastname=User'
                . ' --admin-email=user@example.com --admin-user=%s --admin-password=%s'
                . ' --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1'
                . ' --backend-frontname=%s',
            $input->getOption('admin-user'),
            $input->getOption('admin-password'),
            $input->getOption('backend-path')
        );

        if ($input->getOption('rabbitmq-install')) {
            $amqpModuleExist = exec('cd /var/www/magento2 && php bin/magento module:status | grep Magento_Amqp');

            if ($amqpModuleExist) {
                $rabbitmqHost = $this->requestOption('rabbitmq-host', $input, $output);
                $rabbitmqPort = $this->requestOption('rabbitmq-port', $input, $output);

                $command .= sprintf(
                    ' --amqp-virtualhost=/ --amqp-host=%s --amqp-port=%s --amqp-user=guest --amqp-password=guest',
                    $rabbitmqHost,
                    $rabbitmqPort
                );
            }
        }

        $this->executeCommands($command, $output);

        if (!$input->getOption('use-existing-sources')) {
            if (!file_exists('/var/www/magento2/var/composer_home')) {
                mkdir('/var/www/magento2/var/composer_home', 0777, true);
            }

            copy('/home/magento2/.composer/auth.json', '/var/www/magento2/var/composer_home/auth.json');

            if ($this->requestOption('install-sample-data', $input, $output)) {
                $this->executeCommands(
                    [
                        'cd /var/www/magento2 && php bin/magento sampledata:deploy',
                        'cd /var/www/magento2 && php bin/magento setup:upgrade'
                    ],
                    $output
                );
            }
        }

        $output->writeln('To prepare magento sources run <info>devbox magento:prepare</info> command next');
    }

    /**
     * {@inheritdoc}
     */
    protected function getOptionsConfig()
    {
        return [
            'use-existing-sources' => [
                'initial' => true,
                'boolean' => true,
                'default' => false,
                'description' => 'Whether to use existing sources.',
                'question' => 'Do you want to use existing sources? %default%'
            ],
            'backend-path' => [
                'initial' => true,
                'default' => 'admin',
                'description' => 'Magento backend path.',
                'question' => 'Please enter backend admin path %default%'
            ],
            'admin-user' => [
                'initial' => true,
                'default' => 'admin',
                'description' => 'Admin username.',
                'question' => 'Please enter backend admin username %default%'
            ],
            'admin-password' => [
                'initial' => true,
                'default' => 'admin123',
                'description' => 'Admin password.',
                'question' => 'Please enter backend admin password %default%'
            ],
            'rabbitmq-install' => [
                'initial' => true,
                'boolean' => true,
                'default' => false,
                'description' => 'Whether to install RabbitMQ.',
                'question' => 'Do you want to install RabbitMQ? %default%'
            ],
            'rabbitmq-host' => [
                'requireValue' => false,
                'default' => 'rabbit',
                'description' => 'RabbitMQ host.',
                'question' => 'Please specify RabbitMQ host %default%'
            ],
            'rabbitmq-port' => [
                'requireValue' => false,
                'default' => '5672',
                'description' => 'RabbitMQ port.',
                'question' => 'Please specify RabbitMQ port %default%'
            ],
            'install-sample-data' => [
                'boolean' => true,
                'default' => false,
                'description' => 'Whether to install Sample Data.',
                'question' => 'Do you want to install Sample Data? %default%'
            ]
        ];
    }
}
