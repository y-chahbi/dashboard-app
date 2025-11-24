import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import { parse } from 'csv-parse/sync';

const prisma = new PrismaClient();

interface AgencyCSV {
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  website?: string;
}

interface ContactCSV {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  position?: string;
  agencyName: string;
}

/**
 * Normalize agency name for matching
 * - Trim whitespace
 * - Convert to lowercase
 * - Remove special characters
 */
function normalizeAgencyName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\\s]/gi, '')
    .replace(/\\s+/g, ' ');
}

/**
 * Import agencies from CSV file
 */
async function importAgencies(filePath: string): Promise<Map<string, string>> {
  console.log('📥 Importing agencies...');

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const records: AgencyCSV[] = parse(fileContent, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  });

  const agencyMap = new Map<string, string>(); // normalized name -> id

  for (const record of records) {
    try {
      const agency = await prisma.agency.upsert({
        where: { name: record.name },
        update: {
          email: record.email,
          phone: record.phone,
          address: record.address,
          website: record.website,
        },
        create: {
          name: record.name,
          email: record.email,
          phone: record.phone,
          address: record.address,
          website: record.website,
        },
      });

      const normalizedName = normalizeAgencyName(record.name);
      agencyMap.set(normalizedName, agency.id);
      console.log(`✅ Agency: ${record.name}`);
    } catch (error) {
      console.error(`❌ Failed to import agency: ${record.name}`, error);
    }
  }

  console.log(`✨ Imported ${agencyMap.size} agencies\n`);
  return agencyMap;
}

/**
 * Import contacts from CSV file
 */
async function importContacts(
  filePath: string,
  agencyMap: Map<string, string>
): Promise<void> {
  console.log('📥 Importing contacts...');

  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const records: ContactCSV[] = parse(fileContent, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  });

  let successCount = 0;
  let failCount = 0;

  for (const record of records) {
    try {
      const normalizedAgencyName = normalizeAgencyName(record.agencyName);
      const agencyId = agencyMap.get(normalizedAgencyName);

      if (!agencyId) {
        console.warn(`⚠️  Agency not found for contact: ${record.email} (${record.agencyName})`);
        failCount++;
        continue;
      }

      await prisma.contact.upsert({
        where: { email: record.email },
        update: {
          firstName: record.firstName,
          lastName: record.lastName,
          phone: record.phone,
          position: record.position,
          agencyId,
        },
        create: {
          firstName: record.firstName,
          lastName: record.lastName,
          email: record.email,
          phone: record.phone,
          position: record.position,
          agencyId,
        },
      });

      successCount++;
      console.log(`✅ Contact: ${record.firstName} ${record.lastName}`);
    } catch (error) {
      console.error(`❌ Failed to import contact: ${record.email}`, error);
      failCount++;
    }
  }

  console.log(`\n✨ Imported ${successCount} contacts`);
  if (failCount > 0) {
    console.log(`⚠️  Failed to import ${failCount} contacts`);
  }
}

/**
 * Main import function
 */
async function main() {
  try {
    const agenciesPath = path.join(process.cwd(), 'data', 'agencies.csv');
    const contactsPath = path.join(process.cwd(), 'data', 'contacts.csv');

    // Check if files exist
    if (!fs.existsSync(agenciesPath)) {
      throw new Error(`Agencies file not found: ${agenciesPath}`);
    }
    if (!fs.existsSync(contactsPath)) {
      throw new Error(`Contacts file not found: ${contactsPath}`);
    }

    console.log('🚀 Starting data import...\n');

    // Import agencies first
    const agencyMap = await importAgencies(agenciesPath);

    // Import contacts with agency mapping
    await importContacts(contactsPath, agencyMap);

    console.log('\n🎉 Data import completed successfully!');
  } catch (error) {
    console.error('💥 Import failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();