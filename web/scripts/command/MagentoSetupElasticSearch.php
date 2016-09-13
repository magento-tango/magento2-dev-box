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

class MagentoSetupElasticSearch extends AbstractCommand
{
    /**
     * @var \PDO
     */
    private $pdo;

    /**
     * {@inheritdoc}
     */
    protected function configure()
    {
        $this->setName('magento:setup:elasticsearch')
            ->setDescription('Setup ElasticSearch for Magento')
            ->setHelp('This command allows you to setup ElasticSearch for Magento.');

        parent::configure();
    }

    /**
     * {@inheritdoc}
     */
    public function execute(InputInterface $input, OutputInterface $output)
    {
        $this->getPDOConnection($input)->exec(
            'DELETE FROM core_config_data'
            . ' WHERE path = "catalog/search/elasticsearch_server_hostname" '
            . ' OR path = "catalog/search/elasticsearch_server_port"'
            . ' OR path = "catalog/search/engine";'
        );

        $config = [
            [
                'path' => 'catalog/search/engine',
                'value' => 'elasticsearch'
            ],
            [
                'path' => 'catalog/search/elasticsearch_server_hostname',
                'value' => $input->getOption('elastic-host')
            ],
            [
                'path' => 'catalog/search/elasticsearch_server_port',
                'value' => $input->getOption('elastic-port')
            ]
        ];

        $stmt = $this->getPDOConnection($input)->prepare(
            'INSERT INTO core_config_data (scope, scope_id, path, `value`) VALUES ("default", 0, :path, :value);'
        );

        foreach ($config as $item) {
            $stmt->bindParam(':path', $item['path']);
            $stmt->bindParam(':value', $item['value']);
            $stmt->execute();
        }

        $this->executeCommands('cd ' . $input->getOption('magento-dir') . ' && php bin/magento cache:clean config');
    }

    /**
     * @param InputInterface $input
     * @return \PDO
     */
    private function getPDOConnection(InputInterface $input)
    {
        if ($this->pdo === null) {
            $dsn = 'mysql:dbname=' . $input->getOption('db-name') . ';host=' . $input->getOption('db-host');
            $this->pdo = new \PDO($dsn, $input->getOption('db-user'), $input->getOption('db-password'));
        }
        return $this->pdo;
    }

    /**
     * {@inheritdoc}
     */
    protected function getOptionsConfig()
    {
        return [
            'db-host' => [
                'initial' => true,
                'default' => 'db',
                'description' => 'Magento Mysql host',
                'question' => 'Please enter magento Mysql host %default%'
            ],
            'db-port' => [
                'initial' => true,
                'default' => '3306',
                'description' => 'Magento Mysql port',
                'question' => 'Please enter magento Mysql port %default%'
            ],
            'db-user' => [
                'initial' => true,
                'default' => 'root',
                'description' => 'Magento Mysql user',
                'question' => 'Please enter magento Mysql user %default%'
            ],
            'db-password' => [
                'initial' => true,
                'default' => 'root',
                'description' => 'Magento Mysql password',
                'question' => 'Please enter magento Mysql password %default%'
            ],
            'db-name' => [
                'initial' => true,
                'default' => 'magento2',
                'description' => 'Magento Mysql database',
                'question' => 'Please enter magento Mysql database %default%'
            ],
            'elastic-host' => [
                'initial' => true,
                'default' => 'elasticsearch',
                'description' => 'Magento ElasticSearch host',
                'question' => 'Please enter magento ElasticSearch host %default%'
            ],
            'elastic-port' => [
                'initial' => true,
                'default' => 9200,
                'description' => 'Magento ElasticSearch port',
                'question' => 'Please enter magento ElasticSearch port %default%'
            ],
            'magento-dir' => [
                'initial' => true,
                'default' => '/var/www/magento2',
                'description' => 'Magento root directory',
                'question' => 'Please enter Magento root directory %default%'
            ],
        ];
    }
}
